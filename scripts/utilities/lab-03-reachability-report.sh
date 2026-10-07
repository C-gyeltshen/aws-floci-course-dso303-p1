set -uo pipefail
source configs/course.env; source configs/lab-02.env; source configs/lab-03.env

PASS=0; FAIL=0
check() {  # check "description" "command that exits 0 on success"
  if eval "$2" >/dev/null 2>&1; then printf 'PASS  %s\n' "$1"; PASS=$((PASS+1))
  else printf 'FAIL  %s\n' "$1"; FAIL=$((FAIL+1)); fi
}
q() { aws ec2 "$@" --output text; }

WEB_STATE=$(q describe-instances --instance-ids "$USMS_WEB_INSTANCE" --query 'Reservations[0].Instances[0].State.Name')
DB_STATE=$(q describe-instances --instance-ids "$USMS_DB_INSTANCE" --query 'Reservations[0].Instances[0].State.Name')
WEB_SG=$(q describe-instances --instance-ids "$USMS_WEB_INSTANCE" --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId')
WEB_SUBNET=$(q describe-instances --instance-ids "$USMS_WEB_INSTANCE" --query 'Reservations[0].Instances[0].SubnetId')
DB_SUBNET=$(q describe-instances --instance-ids "$USMS_DB_INSTANCE" --query 'Reservations[0].Instances[0].SubnetId')
WEB_AZ=$(q describe-instances --instance-ids "$USMS_WEB_INSTANCE" --query 'Reservations[0].Instances[0].Placement.AvailabilityZone')
DB_AZ=$(q describe-instances --instance-ids "$USMS_DB_INSTANCE" --query 'Reservations[0].Instances[0].Placement.AvailabilityZone')
PUB_DEFAULT=$(q describe-route-tables --filters "Name=association.subnet-id,Values=$WEB_SUBNET" \
  --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].GatewayId | [0]')
PRIV_DEFAULT=$(q describe-route-tables --filters "Name=association.subnet-id,Values=$DB_SUBNET" \
  --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].[GatewayId,NatGatewayId] | [0][0]')
DB_FROM_SG=$(q describe-security-groups --group-ids "$USMS_DB_SG" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`5432`].UserIdGroupPairs[0].GroupId | [0]')

echo "===== USMS reachability report ====="
check "1. web instance is running"                          "[ '$WEB_STATE' = running ]"
check "2. db instance is running"                           "[ '$DB_STATE' = running ]"
check "3. web subnet default route goes to an IGW"          "[[ '$PUB_DEFAULT' == igw-* ]]"
check "4. IGW is attached to the VPC"                       "[ \"\$(q describe-internet-gateways --internet-gateway-ids $USMS_IGW_ID --query 'InternetGateways[0].Attachments[0].State')\" = available ]"
check "5. db subnet has NO route to an IGW"                 "[[ '$PRIV_DEFAULT' != igw-* ]]"
check "6. db subnet has no NAT/IGW default route (isolated)" "[ '$PRIV_DEFAULT' = None ] || [[ '$PRIV_DEFAULT' != igw-* ]]"
check "7. web SG admits TCP 80 from 0.0.0.0/0"              "[ \"\$(q describe-security-groups --group-ids $USMS_APP_SG --query 'SecurityGroups[0].IpPermissions[?FromPort==\`80\`].IpRanges[0].CidrIp | [0]')\" = 0.0.0.0/0 ]"
check "8. db SG admits 5432 only from the web SG"           "[ '$DB_FROM_SG' = '$WEB_SG' ]"
check "9. db SG has no 0.0.0.0/0 ingress"                   "[ \"\$(q describe-security-groups --group-ids $USMS_DB_SG --query 'length(SecurityGroups[0].IpPermissions[].IpRanges[?CidrIp==\`0.0.0.0/0\`][])')\" = 0 ]"
check "10. web SG egress allows all outbound"               "[ \"\$(q describe-security-groups --group-ids $USMS_APP_SG --query 'SecurityGroups[0].IpPermissionsEgress[?IpProtocol==\`-1\`] | length(@)')\" -ge 1 ]"
check "11. web subnet NACL exists"                          "[ -n \"\$(q describe-network-acls --filters Name=association.subnet-id,Values=$WEB_SUBNET --query 'NetworkAcls[0].NetworkAclId')\" ]"
check "12. db subnet NACL exists"                           "[ -n \"\$(q describe-network-acls --filters Name=association.subnet-id,Values=$DB_SUBNET --query 'NetworkAcls[0].NetworkAclId')\" ]"
check "13. web and db are in the same VPC"                  "[ \"\$(q describe-subnets --subnet-ids $WEB_SUBNET $DB_SUBNET --query 'length(Subnets[?VpcId==\`$USMS_VPC_ID\`])')\" = 2 ]"
echo "AZ: web=$WEB_AZ  db=$DB_AZ  (cross-AZ: $([ "$WEB_AZ" = "$DB_AZ" ] && echo no || echo yes))"

echo
echo "===== Allowed-flow matrix ====="
printf '%-22s %-22s %-8s %s\n' FROM TO PORT VERDICT
printf '%-22s %-22s %-8s %s\n' internet web   80   "$([ "$PUB_DEFAULT" != "" ] && echo ALLOW || echo DENY)"
printf '%-22s %-22s %-8s %s\n' web      db    5432 "$([ "$DB_FROM_SG" = "$WEB_SG" ] && echo ALLOW || echo DENY)"
printf '%-22s %-22s %-8s %s\n' internet db    5432 DENY
printf '%-22s %-22s %-8s %s\n' db       internet any "$([[ "$PRIV_DEFAULT" == igw-* ]] && echo ALLOW || echo DENY)"

echo; echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]