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

