# **Lab 1 - Identity and Access Management**

## **PART A — Environment Setup**

### Step 1 — Open a terminal and identify your system

```bash
uname -s -m
echo "shell = $SHELL"
echo "home  = $HOME"
```

![1](../../screenshots/lab1/1.png)

`echo "shell = $SHELL"
echo "home  = $HOME"
Darwin arm64
shell = /bin/zsh
home  = /Users/chimigyeltshen
`

### Step 2 — Verify Docker and Docker Compose

```bash
docker --version
docker info --format '{{.ServerVersion}}'
docker compose version
```

![2](../../screenshots/lab1/2.png)

### Step 3 — Install the Floci CLI

```bash
floci version
```

![3](../../screenshots/lab1/3.png)

### Step 4 — Run Floci's environment diagnostics¶

```bash
floci doctor
```

![4](../../screenshots/lab1/4.png)

### Step 5 — Create the course directory structure

```bash
tree
```

![5](../../screenshots/lab1/5.png)

### Write .gitignore and initialise Git — before any secret exists

```bash
touch .gitignore
git init
git add .
git commit -m "wip: p1"
git remote add origin https://github.com/C-gyeltshen/aws-floci-course-dso303-p1.git
git branch -M main
git push -u origin main
```

![6](../../screenshots/lab1/6.png)

### Floci Storage Models Overview

Floci provides two distinct storage modes for persisting state across container restarts and setups:

#### **_1. Ephemeral Mode (Default)_**

- **Behavior:** Data is stored strictly in container memory/tmpfs.
- **Persistence:** All IAM users, roles, policies, and S3 objects are completely wiped when the Docker container stops or restarts.
- **Use Case:** Quick isolated testing, stateless CI/CD runs, and quick experimentations where persistent state is unnecessary.

#### **_2. Persistent Mode_**

- **Behavior:** Floci maps state data to a host directory using a Docker bind mount (configured via `FLOCI_HOST_DATA_DIR`).
- **Persistence:** AWS resources and configurations persist across container restarts and system reboots.

### Step 8 — Write docker-compose.yml and configs/course.env

```bash
docker compose config >/dev/null && echo "compose file is valid"
```

![7](../../screenshots/lab1/7.png)

### Step 9 — Write the start/stop scripts and bring Floci up¶

- create `scripts/setup/floci-up.sh`
- create `scripts/setup/floci-down.sh`
- run floci-up.sh file

```bash
chmod +x scripts/setup/floci-down.sh
./scripts/setup/floci-up.sh
```

![8](../../screenshots/lab1/8.png)
there was already floci container from Lab0 so i had to stop the container and remove it for LAb1.

### Step 10 — Install the AWS CLI

```bash
curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg
```

![9](../../screenshots/lab1/9.png)

### AWS Core Concepts: Credentials, Regions, and Profiles

#### 1. AWS Regions

An **AWS Region** is a distinct, geographically isolated physical location in the world where AWS clusters data centers.

- **Why Regions Matter:**
  - **Latency:** Deploy resources physically closer to end users to reduce response times.
  - **Data Sovereignty & Compliance:** Ensure compliance with national data privacy and governance laws.
  - **Cost:** Service pricing varies slightly across different regions due to operational costs.
- **Global vs. Regional Services:** Most AWS services (e.g., S3, EC2, DynamoDB) are scoped to a specific region. However, **IAM (Identity and Access Management)** is a **global service**—IAM users, groups, roles, and policies apply universally across all regions.
- **Naming Format:** Regions use geographic codes, e.g., `us-east-1` (N. Virginia), `eu-west-1` (Ireland), or `ap-southeast-1` (Singapore).

#### 2. Credential Resolution Order

When you execute an AWS CLI command or SDK call, the tools evaluate potential credential sources in a **strict top-down order of precedence**. The first valid credential found is used:

1. **Command Line Options:** Direct inline flags (e.g., `--region us-east-1` or `--profile floci`).
2. **Environment Variables:** Session variables like `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_PROFILE`.
3. **AWS Credentials File:** Access keys specified in `~/.aws/credentials`.
4. **AWS Config File:** Default settings and named profile configurations in `~/.aws/config`.
5. **Container Credentials:** IAM roles provided by ECS tasks or EKS pod identities.
6. **Instance Profile Credentials:** Temporary credentials retrieved automatically via the EC2 Instance Metadata Service (IMDS).

#### 3. AWS Profiles

An **AWS Profile** is a named collection of credentials and default parameters (like region and output format) stored in your local configuration files (`~/.aws/config` and `~/.aws/credentials`).

#### Why Profiles Are Essential

Profiles allow you to seamlessly switch between multiple AWS environments (e.g., `default`, `production`, `sandbox`, or local mock tools like `floci`) on a single machine without constantly overriding environment variables.

### Step 12 — Create the floci AWS CLI profile

```bash
aws configure set aws_access_key_id     test                  --profile floci
aws configure set aws_secret_access_key test                  --profile floci
aws configure set region                us-east-1             --profile floci
aws configure set output                json                  --profile floci
aws configure set endpoint_url          http://localhost:4566 --profile floci
```
![10](../../screenshots/lab1/10.png)
![11](../../screenshots/lab1/11.png)

### Step 13 — Your first AWS CLI command, and the whoami helper

```bash
aws sts get-caller-identity --profile floci
```
![12](../../screenshots/lab1/12.png)
![13](../../screenshots/lab1/13.png)

### Step 14 — Prove isolation from real AWS, and prove persistence

```bash
aws sts get-caller-identity --profile floci --debug 2>&1 \
  | grep -i "endpoint\|Making request" \
  | head -5
```

```bash
./scripts/setup/floci-down.sh
aws sts get-caller-identity --profile floci
```
![14](../../screenshots/lab1/14.png)

persist the data

```bash
# 1. Bring Floci back up
./scripts/setup/floci-up.sh

# 2. Create a marker resource
aws iam create-user --user-name persistence-check --output text --query 'User.Arn'

# 3. Restart the container — a full stop and start, not just a pause
docker compose restart floci
sleep 5
until curl -sf http://localhost:4566/_floci/health >/dev/null 2>&1; do sleep 2; done

# 4. Is it still there?
aws iam get-user --user-name persistence-check --query 'User.UserName' --output text
```
![15](../../screenshots/lab1/15.png)

Cleaning up the marker

```bash
aws iam delete-user --user-name persistence-check
```
Exit code 

```bash
aws sts get-caller-identity --profile floci > /dev/null 2>&1
echo "exit code = $?"

aws iam get-user --user-name does-not-exist > /dev/null 2>&1
echo "exit code = $?"
```

![16](../../screenshots/lab1/16.png)

### Step 15 — Storage diagnostics, README, and commit Part A

Creating scripts/utilities/floci-storage-check.sh and running it.

![17](../../screenshots/lab1/17.png)

cleanup script for stray volume
![18](../../screenshots/lab1/18.png)

Push Part A to GitHub

```bash
git add .
git commit -m "wip: p1"
git push
```
![19](../../screenshots/lab1/19.png)


## PART B — Building the IAM Foundation

### Step 17 — Inspect the empty IAM account

```bash
aws iam list-users
```
![20](../../screenshots/lab2/1.png)

```bash
aws iam list-users --output json
aws iam list-users --output table
aws iam list-users --output text
```
![21](../../screenshots/lab2/2.png)

### Step 18 — Create the IAM groups

```bash
aws iam create-group --group-name usms-admins
aws iam create-group --group-name usms-developers
aws iam create-group --group-name usms-auditors
```
![22](../../screenshots/lab2/3.png)

verify
```bash
aws iam list-groups --query 'Groups[*].[GroupName,Arn]' --output table
```
![23](../../screenshots/lab2/4.png)

### Step 19 — Create the IAM users and capture their ARNs

```bash
ADMIN_ARN=$(aws iam create-user \
  --user-name usms-admin-01 \
  --tags Key=Project,Value=USMS Key=Role,Value=Administrator \
  --query 'User.Arn' \
  --output text)

DEV_ARN=$(aws iam create-user \
  --user-name usms-dev-01 \
  --tags Key=Project,Value=USMS Key=Role,Value=Developer \
  --query 'User.Arn' \
  --output text)

AUDIT_ARN=$(aws iam create-user \
  --user-name usms-audit-01 \
  --tags Key=Project,Value=USMS Key=Role,Value=Auditor \
  --query 'User.Arn' \
  --output text)

echo "$ADMIN_ARN"
echo "$DEV_ARN"
echo "$AUDIT_ARN"
```
![24](../../screenshots/lab2/5.png)

verify 
```bash
aws iam list-users \
  --query 'Users[*].{User:UserName,Created:CreateDate,Arn:Arn}' \
  --output table
```
![25](../../screenshots/lab2/6.png)

### Step 20 — Add users to groups

```bash
aws iam add-user-to-group --group-name usms-admins     --user-name usms-admin-01
aws iam add-user-to-group --group-name usms-developers --user-name usms-dev-01
aws iam add-user-to-group --group-name usms-auditors   --user-name usms-audit-01
```
![26](../../screenshots/lab2/7.png)

### Step 21 — Explore and attach an AWS managed policy

```bash
aws iam attach-group-policy \
  --group-name usms-auditors \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```
![27](../../screenshots/lab2/8.png)

verify
```bash
aws iam list-attached-group-policies --group-name usms-auditors --output table
```
![28](../../screenshots/lab2/9.png)

### Step 22 — Write your first customer managed policy

![29](../../screenshots/lab2/10.png)

verify the json before sending it
```bash 
cd policies
python3 -m json.tool usms-developer-base-policy.json > /dev/null && echo "Valid JSON"
```
![30](../../screenshots/lab2/11.png)

create the policy
```bash
DEV_POLICY_ARN=$(aws iam create-policy \
  --policy-name USMSDeveloperBase \
  --description "Read infrastructure + build VPC networking for USMS. Denies identity escalation." \
  --policy-document file://usms-developer-base-policy.json \
  --query 'Policy.Arn' \
  --output text)

echo "$DEV_POLICY_ARN"
```
![31](../../screenshots/lab2/12.png)

Attach it to both groups that need it
```bash
aws iam attach-group-policy --group-name usms-developers --policy-arn "$DEV_POLICY_ARN"
aws iam attach-group-policy --group-name usms-admins     --policy-arn "$DEV_POLICY_ARN"
```
![32](../../screenshots/lab2/13.png)

verify
```bash
aws iam list-attached-group-policies --group-name usms-developers --output table
aws iam get-policy --policy-arn "$DEV_POLICY_ARN" \
  --query 'Policy.{Name:PolicyName,Attached:AttachmentCount,Default:DefaultVersionId}' \
  --output table
```
![33](../../screenshots/lab2/14.png)

### Step 23 — Write the S3 data policy (used for real in Lab 4)

```bash
cd policies
touch usms-student-data-rw-policy.json

S3_POLICY_ARN=$(aws iam create-policy \
  --policy-name USMSStudentDataReadWrite \
  --description "Read/write student transcripts in the USMS bucket. Bucket deletion denied." \
  --policy-document file://usms-student-data-rw-policy.json \
  --query 'Policy.Arn' --output text)

echo "$S3_POLICY_ARN"
```
![34](../../screenshots/lab2/15.png)

verify
```bash
aws iam list-policies --scope Local \
  --query 'Policies[*].{Name:PolicyName,Attached:AttachmentCount}' --output table
```
![35](../../screenshots/lab2/16.png)

### Step 24 — Use --generate-cli-skeleton to discover parameters

```bash 
cd templates
aws iam create-role --generate-cli-skeleton > create-role-skeleton.json
cat create-role-skeleton.json
```
![36](../../screenshots/lab2/17.png)

### Step 25 — Add an inline policy

```bash   
cd policies
touch usms-self-manage-credentials.json
```
![37](../../screenshots/lab2/18.png)

verify 
```bash
aws iam list-user-policies --user-name usms-dev-01
aws iam get-user-policy --user-name usms-dev-01 --policy-name USMSSelfManageCredentials
```
![38](../../screenshots/lab2/19.png)

### Step 26 — Inspect what you have built
```bash
IAM_USER=usms-dev-01
echo "=== groups ===";      aws iam list-groups-for-user       --user-name $IAM_USER --query 'Groups[*].GroupName'                --output text
echo "=== attached ===";    aws iam list-attached-user-policies --user-name $IAM_USER --query 'AttachedPolicies[*].PolicyName'    --output text
echo "=== inline ===";      aws iam list-user-policies          --user-name $IAM_USER --query 'PolicyNames'                       --output text
echo "=== access keys ==="; aws iam list-access-keys            --user-name $IAM_USER --query 'AccessKeyMetadata[*].AccessKeyId'  --output text
```
![39](../../screenshots/lab2/20.png)

```bash 
POLICY_ARN=arn:aws:iam::000000000000:policy/USMSDeveloperBase
VER=$(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)

aws iam get-policy-version \
  --policy-arn $POLICY_ARN \
  --version-id $VER \
  --query 'PolicyVersion.Document'
```
![40](../../screenshots/lab2/21.png)

### Step 27 — Policy versions
```bash 
python3 - << 'PY'
import json, pathlib
p = pathlib.Path("usms-developer-base-policy.json")
doc = json.loads(p.read_text())
for st in doc["Statement"]:
    if st.get("Sid") == "BuildNetworkingForLab02":
        st["Action"] += ["ec2:DeleteVpc", "ec2:DescribeAvailabilityZones"]
pathlib.Path("usms-developer-base-policy-v2.json").write_text(json.dumps(doc, indent=2))
print("wrote usms-developer-base-policy-v2.json")
PY

aws iam create-policy-version \
  --policy-arn arn:aws:iam::000000000000:policy/USMSDeveloperBase \
  --policy-document file://usms-developer-base-policy-v2.json \
  --set-as-default

```
![41](../../screenshots/lab2/23.png)

verfiy 
```bash
aws iam list-policy-versions \
  --policy-arn arn:aws:iam::000000000000:policy/USMSDeveloperBase \
  --query 'Versions[*].{Version:VersionId,Default:IsDefaultVersion,Created:CreateDate}' \
  --output table
```
![42](../../screenshots/lab2/24.png)

### Step 28 — Create a role for EC2, with a trust policy
```bash 
EC2_ROLE_ARN=$(aws iam create-role \
  --role-name usms-ec2-app-role \
  --description "Role for the USMS application server (Lab 03). Grants S3 access to student data." \
  --assume-role-policy-document file://trust-ec2.json \
  --tags Key=Project,Value=USMS \
  --query 'Role.Arn' --output text)

echo "$EC2_ROLE_ARN"
```
![43](../../screenshots/lab2/25.png)

providing permissions to each role 
```bash
aws iam attach-role-policy \
  --role-name usms-ec2-app-role \
  --policy-arn arn:aws:iam::000000000000:policy/USMSStudentDataReadWrite

```
![44](../../screenshots/lab2/26.png)
```bash
aws iam get-role --role-name usms-ec2-app-role \
  --query 'Role.{Name:RoleName,Arn:Arn,Trust:AssumeRolePolicyDocument.Statement[0].Principal}' \
  --output json

aws iam list-attached-role-policies --role-name usms-ec2-app-role --output table
```
![45](../../screenshots/lab2/27.png)


Create the instance profile
```bash 
aws iam create-instance-profile --instance-profile-name usms-ec2-app-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name usms-ec2-app-profile \
  --role-name usms-ec2-app-role
```
![46](../../screenshots/lab2/28.png)

verify
```bash 
aws iam get-instance-profile --instance-profile-name usms-ec2-app-profile \
  --query 'InstanceProfile.{Profile:InstanceProfileName,Roles:Roles[*].RoleName}' \
  --output json
```
![47](../../screenshots/lab2/29.png)

### Step 29 — Create the Lambda execution role
![48](../../screenshots/lab2/30.png)

![49](../../screenshots/lab2/31.png)

### Step 30 — A role for humans, and temporary credentials with STS¶
```bash 
DEVROLE_ARN=$(aws iam create-role \
  --role-name usms-developer-role \
  --description "Elevated build permissions, assumed temporarily by USMS developers." \
  --assume-role-policy-document file://trust-account-developers.json \
  --max-session-duration 3600 \
  --query 'Role.Arn' --output text)

aws iam attach-role-policy \
  --role-name usms-developer-role \
  --policy-arn arn:aws:iam::000000000000:policy/USMSDeveloperBase

echo "$DEVROLE_ARN"
```
![50](../../screenshots/lab2/32.png)

![51](../../screenshots/lab2/33.png)

 Use the temporary credentials, then put your identity back

 ```bash 
export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId'         outputs/assumed-role.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' outputs/assumed-role.json)
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken'        outputs/assumed-role.json)

aws sts get-caller-identity --endpoint-url http://localhost:4566 --region us-east-1
```
![52](../../screenshots/lab2/34.png)

```bash 
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
./scripts/utilities/whoami.sh
```
![53](../../screenshots/lab2/35.png)

### Step 31 — Access keys, handled safely¶

```bash 
aws iam create-access-key --user-name usms-dev-01 \
  > outputs/usms-dev-01-access-key.json

chmod 600 outputs/usms-dev-01-access-key.json
```
![54](../../screenshots/lab2/36.png)

verify
```bash
aws iam list-access-keys --user-name usms-dev-01 \
  --query 'AccessKeyMetadata[*].{Key:AccessKeyId,Status:Status,Created:CreateDate}' \
  --output table
```
![55](../../screenshots/lab2/37.png)

### Step 32 — Test permissions with the policy simulator¶

```bash 
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::000000000000:user/usms-dev-01 \
  --action-names "ec2:CreateVpc" "iam:CreateUser" "s3:GetObject" \
  --query 'EvaluationResults[*].{Action:EvalActionName,Decision:EvalDecision}' \
  --output table
```
![56](../../screenshots/lab2/38.png)

### Step 33 — Save the lab state for future labs

```bash
grep -n 'export .*=$\|None' configs/lab-01.env || echo "all values populated"
```

```bash 
source configs/course.env
source configs/lab-01.env
echo "EC2 role  : $USMS_ROLE_EC2"
echo "Dev policy: $USMS_POLICY_DEV_BASE"
```
![57](../../screenshots/lab2/39.png)

floci snapshort 
![58](../../screenshots/lab2/40.png)

Pushing Part B to GitHub

```bash
git add .
git commit -m "wip: p2"
git push
```