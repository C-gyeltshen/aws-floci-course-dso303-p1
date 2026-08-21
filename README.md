# AWS CLI + Floci - USMS Course Project

This repository contains the lab work for building the **University Student
Management System (USMS)** infrastructure with the AWS CLI against
[Floci](https://floci.io), a local AWS emulator.

The project is designed for repeatable AWS practice without touching a real AWS
account. Floci runs in Docker, exposes an AWS-compatible endpoint on
`http://localhost:4566`, and stores lab state on disk so IAM resources survive
container restarts.

## What This Project Covers

- Local AWS emulation with Floci and Docker Compose
- AWS CLI profile setup for a local endpoint
- Persistent emulator state using a host bind mount
- IAM users, groups, policies, roles, instance profiles, and STS
- Course-safe scripts for starting, stopping, verifying, and diagnosing the lab
- Screenshots and lab notes for submission evidence

## Repository Layout

```text
.
├── configs/                 # Shared environment variables for the course/labs
├── labs/                    # Lab writeups and step-by-step documentation
│   └── lab-01-iam/
├── outputs/                 # Generated CLI outputs and secrets; ignored by Git
├── policies/                # IAM permission and trust policy JSON files
├── screenshots/             # Lab screenshots for reports/submission
├── scripts/
│   ├── cleanup/             # Explicit cleanup utilities
│   ├── setup/               # Floci start/stop scripts
│   └── utilities/           # Verification and diagnostic helpers
├── templates/               # AWS CLI generated skeletons/templates
├── docker-compose.yml       # Floci container and persistence configuration
└── README.md
```

## Prerequisites

Install these before starting the labs:

- Docker Desktop or Docker Engine with Docker Compose v2
- Floci CLI
- AWS CLI v2
- `curl`
- `jq`
- Git

Check the core tools:

```bash
docker --version
docker compose version
floci version
aws --version
jq --version
```

On macOS, the AWS CLI installer can be downloaded with:

```bash
curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
```

## Quick Start

From the repository root:

```bash
source configs/course.env
./scripts/setup/floci-up.sh
```

Configure the AWS CLI profile used by the course:

```bash
aws configure set aws_access_key_id     test                  --profile floci
aws configure set aws_secret_access_key test                  --profile floci
aws configure set region                us-east-1             --profile floci
aws configure set output                json                  --profile floci
aws configure set endpoint_url          http://localhost:4566 --profile floci
```

Confirm that the CLI is talking to Floci, not real AWS:

```bash
./scripts/utilities/whoami.sh
```

Expected account:

```text
000000000000
```

## Daily Workflow

Start or resume the local AWS environment:

```bash
source configs/course.env
./scripts/setup/floci-up.sh
```

Do the lab work with the `floci` AWS profile:

```bash
aws sts get-caller-identity
aws iam list-users
```

Pause the environment while keeping state:

```bash
./scripts/setup/floci-down.sh
```

## Configuration

The shared course settings live in [configs/course.env](configs/course.env).

Important defaults:

| Setting | Value | Purpose |
|---|---:|---|
| `AWS_PROFILE` | `floci` | AWS CLI profile used by the labs |
| `FLOCI_ENDPOINT` | `http://localhost:4566` | Local AWS-compatible endpoint |
| `AWS_REGION_COURSE` | `us-east-1` | Course region |
| `ACCOUNT_ID` | `000000000000` | Floci's local account ID |
| `PROJECT` | `usms` | Resource naming prefix |
| `FLOCI_STORAGE_MODE` | `hybrid` | Durable Floci storage mode |
| `FLOCI_HOST_DATA_DIR` | `$HOME/floci-data` | Host directory for persisted state |

Lab-specific resource names and ARNs are collected in
[configs/lab-01.env](configs/lab-01.env) after the IAM lab resources exist.

## Floci Persistence Model

This project intentionally avoids Floci's default memory-only mode.

State is persisted by mounting the host directory from `FLOCI_HOST_DATA_DIR` into
the Floci container at `/app/data`. The Compose file uses an absolute path
written to `.env` by `scripts/setup/floci-up.sh`, because Docker Compose does
not expand `~` reliably in volume paths.

Use this diagnostic when state appears to disappear:

```bash
./scripts/utilities/floci-storage-check.sh
```

## Safety Rules

These commands can destroy lab state or bypass the repository's persistence
setup:

| Do Not Run | Why |
|---|---|
| `docker compose down -v` | Deletes Docker volumes |
| `docker volume prune` | Deletes unfiltered volumes; use the cleanup script instead |
| `floci start ...` | Starts a separate container outside this Compose setup |
| `rm -rf ~/floci-data` | Deletes persisted Floci state |
| AWS CLI commands without checking the profile | Could accidentally target real AWS |

Before running AWS commands, verify the identity:

```bash
./scripts/utilities/whoami.sh
```

## Labs

| Lab | Topic | Location | Status |
|---:|---|---|---|
| 01 | IAM and environment setup | [labs/lab-01-iam](labs/lab-01-iam) | Complete |
| 02 | VPC | Planned | Not started |

### Lab 01 Summary

Lab 01 builds the IAM foundation for USMS:

- Groups: `usms-admins`, `usms-developers`, `usms-auditors`
- Users: `usms-admin-01`, `usms-dev-01`, `usms-audit-01`
- Customer managed policies:
  - `USMSDeveloperBase`
  - `USMSStudentDataReadWrite`
  - `USMSAssumeAppRoles`
  - `USMSLambdaBasic`
- Roles:
  - `usms-ec2-app-role`
  - `usms-lambda-exec-role`
  - `usms-developer-role`
- Instance profile:
  - `usms-ec2-app-profile`
- STS assume-role practice with temporary credentials
- Safe access-key handling in ignored `outputs/` files

Run the Lab 01 verifier:

```bash
./scripts/utilities/verify-lab-01.sh
```

## IAM Policy Files

The reusable IAM policy documents live in [policies](policies):

| File | Purpose |
|---|---|
| `usms-developer-base-policy.json` | Base developer permissions |
| `usms-developer-base-policy-v2.json` | Updated developer policy version |
| `usms-student-data-rw-policy.json` | S3 read/write access for student data |
| `usms-assume-app-roles-policy.json` | Permission to assume USMS application roles |
| `usms-lambda-basic-policy.json` | Basic Lambda execution permissions |
| `usms-self-manage-credentials.json` | Inline user credential self-management policy |
| `trust-ec2.json` | EC2 role trust policy |
| `trust-lambda.json` | Lambda role trust policy |
| `trust-account-developers.json` | Human developer role trust policy |

Validate a policy before creating it:

```bash
python3 -m json.tool policies/usms-developer-base-policy.json > /dev/null
```

## Secrets and Generated Outputs

The [outputs](outputs) directory is for generated command output, including
temporary STS responses and access keys. Files in this directory are ignored by
Git except for an optional `.gitkeep`.

Examples of ignored sensitive files:

- `outputs/assumed-role.json`
- `outputs/usms-dev-01-access-key.json`
- `*-access-key.json`
- files matching `*credentials*`

If access keys are generated during a lab, restrict the file permissions:

```bash
chmod 600 outputs/usms-dev-01-access-key.json
```

## Common Commands

Start Floci:

```bash
./scripts/setup/floci-up.sh
```

Stop Floci without deleting state:

```bash
./scripts/setup/floci-down.sh
```

Check the active AWS identity:

```bash
./scripts/utilities/whoami.sh
```

Check Floci storage configuration:

```bash
./scripts/utilities/floci-storage-check.sh
```

Verify Lab 01:

```bash
./scripts/utilities/verify-lab-01.sh
```

List local IAM policies:

```bash
aws iam list-policies --scope Local --output table
```

List IAM groups and users:

```bash
aws iam list-groups --output table
aws iam list-users --output table
```

## Troubleshooting

### Docker is not running

Start Docker Desktop, then run:

```bash
./scripts/setup/floci-up.sh
```

### Port 4566 is already in use

Check what owns the port:

```bash
lsof -i :4566
```

Stop the conflicting process or container, then start Floci again.

### A container named `floci` already exists

The setup script refuses to continue if another container named `floci` was not
created by this Compose project. Remove that stray container, then restart:

```bash
floci stop --remove
./scripts/setup/floci-up.sh
```

If that does not remove it:

```bash
docker rm -f floci
./scripts/setup/floci-up.sh
```

### AWS CLI cannot reach Floci

Check that the container is healthy:

```bash
curl -sf http://localhost:4566/_floci/health
docker compose ps
```

Then verify the AWS profile:

```bash
aws configure get endpoint_url --profile floci
aws configure get region --profile floci
```

### Lab state disappeared

Run the storage diagnostic:

```bash
./scripts/utilities/floci-storage-check.sh
```

Confirm that:

- `FLOCI_STORAGE_MODE` is `hybrid`, `persistent`, or `wal`
- `/app/data` is a bind mount
- `FLOCI_HOST_DATA_DIR` points to an absolute host path
- `~/floci-data` exists and is not empty

## Git Hygiene

Tracked source files should include:

- lab instructions
- scripts
- configuration templates
- IAM policy JSON
- screenshots required for submission

Ignored files should include:

- `.env`
- local Floci state
- generated access keys
- temporary credentials
- command output under `outputs/`

Before committing, check:

```bash
git status --short
git check-ignore -q outputs/usms-dev-01-access-key.json && echo "access key is ignored"
git check-ignore -q .env && echo ".env is ignored"
```

## Naming Conventions

- Project prefix: `usms-`
- AWS profile: `floci`
- Region: `us-east-1`
- Local account ID: `000000000000`
- Floci container name: `floci`
- Compose project name: `floci-course`
- Host state directory: `~/floci-data`

## Notes

This repository is for local lab work. It is intentionally configured to use the
Floci endpoint and dummy credentials. Do not reuse these policies or commands
against a real AWS account without reviewing and adapting them first.
