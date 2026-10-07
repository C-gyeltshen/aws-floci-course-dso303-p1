set -uo pipefail
source configs/course.env; source configs/lab-01.env; source configs/lab-03.env
MANIFEST=configs/lab-04-handoff.json
FAIL=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; FAIL=1; }

BUCKET=$(python3 -c "import json;print(json.load(open('$MANIFEST'))['bucket'])")

python3 -m json.tool "$MANIFEST" >/dev/null 2>&1 && ok "manifest is valid JSON" || bad "manifest invalid"

STATE=$(aws ec2 describe-instances --instance-ids "$USMS_WEB_INSTANCE" \
  --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
[ "$STATE" = running ] && ok "web instance running" || bad "web instance state: $STATE"

ROLE=$(aws iam get-instance-profile --instance-profile-name "$USMS_INSTANCE_PROFILE" \
  --query 'InstanceProfile.Roles[0].RoleName' --output text 2>/dev/null)
[ -n "$ROLE" ] && [ "$ROLE" != None ] && ok "profile has role $ROLE" || bad "profile has no role"

aws iam list-attached-role-policies --role-name "$ROLE" \
  --query 'AttachedPolicies[].PolicyName' --output text 2>/dev/null | grep -q USMSStudentDataReadWrite \
  && ok "USMSStudentDataReadWrite attached" || bad "policy not attached"

aws s3api head-bucket --bucket "$BUCKET" >/dev/null 2>&1 \
  && ok "bucket $BUCKET exists" || echo "WARN  bucket $BUCKET not created yet (Lab 4 creates it)"

exit $FAIL