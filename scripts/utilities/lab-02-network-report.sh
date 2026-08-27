#!/usr/bin/env bash
set -uo pipefail

# Resolve paths relative to this script, not the caller's cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$PROJECT_ROOT/configs/course.env"
source "$PROJECT_ROOT/configs/lab-02.env"

VPC_ID="$USMS_VPC_ID"

MAIN_RT_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'sort_by(Subnets, &CidrBlock)[].SubnetId' \
  --output text)

for SUBNET_ID in $SUBNET_IDS; do
  read -r NAME CIDR AZ <<< "$(aws ec2 describe-subnets \
    --subnet-ids "$SUBNET_ID" \
    --query 'Subnets[0].[Tags[?Key==`Name`]|[0].Value,CidrBlock,AvailabilityZone]' \
    --output text)"

  RT_ID=$(aws ec2 describe-route-tables \
    --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

  if [[ -z "$RT_ID" || "$RT_ID" == "None" ]]; then
    RT_ID="$MAIN_RT_ID"
  fi

  DEFAULT_ROUTE=$(aws ec2 describe-route-tables \
    --route-table-ids "$RT_ID" \
    --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`] | [0]' \
    --output json)

  GW_ID=$(echo "$DEFAULT_ROUTE" | jq -r '.GatewayId // empty')
  NAT_ID=$(echo "$DEFAULT_ROUTE" | jq -r '.NatGatewayId // empty')

  if [[ "$GW_ID" == igw-* ]]; then
    printf '%-24s%-15s%-14s%-9s via %s\n' "$NAME" "$CIDR" "$AZ" "PUBLIC" "$GW_ID"
  elif [[ -n "$NAT_ID" ]]; then
    printf '%-24s%-15s%-14s%-9s via %s\n' "$NAME" "$CIDR" "$AZ" "PRIVATE" "$NAT_ID"
  else
    printf '%-24s%-15s%-14s%-9s no default route\n' "$NAME" "$CIDR" "$AZ" "ISOLATED"
  fi
done
