# USMS on Floci — AWS CLI Course Labs

> Hands-on AWS CLI labs that build the **University Student Management System
> (USMS)** infrastructure against [Floci](https://floci.io), a local AWS
> emulator. No real AWS account, no cost, and lab state that survives restarts.

| | |
|---|---|
| **Endpoint** | `http://localhost:4566` |
| **AWS profile** | `floci` |
| **Region** | `us-east-1` |
| **Account ID** | `000000000000` |
| **Resource prefix** | `usms-` |

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture](#2-architecture)
3. [Repository Layout](#3-repository-layout)
4. [Prerequisites](#4-prerequisites)
5. [Quick Start](#5-quick-start)
6. [Daily Workflow](#6-daily-workflow)
7. [Configuration](#7-configuration)
8. [Persistence Model](#8-persistence-model)
9. [Safety Rules](#9-safety-rules)
10. [Labs](#10-labs)
11. [IAM Policy Files](#11-iam-policy-files)
12. [Secrets and Generated Outputs](#12-secrets-and-generated-outputs)
13. [Command Reference](#13-command-reference)
14. [Troubleshooting](#14-troubleshooting)
15. [Git Hygiene](#15-git-hygiene)
16. [Naming Conventions](#16-naming-conventions)

---

## 1. Overview

This repository is designed for **repeatable AWS practice** without touching a
real AWS account. Floci runs in Docker, exposes an AWS-compatible API on port
`4566`, and writes its state to a host directory so resources persist across
container restarts.

**What you will practise**

- Local AWS emulation with Floci and Docker Compose
- AWS CLI profile setup for a local endpoint
- Persistent emulator state using a host bind mount
- IAM users, groups, policies, roles, instance profiles, and STS
- Course-safe scripts to start, stop, verify, and diagnose the lab
- Capturing screenshots and notes as submission evidence

---

## 2. Architecture

```text
┌──────────────────────┐        ┌────────────────────────────────────┐
│  Your machine        │        │  Docker (Compose project:          │
│                      │        │          floci-course)             │
│  aws --profile floci │ ─────► │  ┌──────────────────────────────┐  │
│  scripts/*.sh        │  HTTP  │  │ container: floci             │  │
│                      │ :4566  │  │ AWS-compatible API           │  │
│  ~/floci-data  ◄─────┼────────┼──┤ /app/data  (bind mount)      │  │
│  (persisted state)   │        │  └──────────────────────────────┘  │
└──────────────────────┘        └────────────────────────────────────┘
```

---

## 3. Repository Layout

```text
.
├── configs/                 # Shared environment variables (course + per-lab)
├── labs/                    # Lab write-ups and step-by-step documentation
│   └── lab-01-iam/
├── outputs/                 # Generated CLI output and secrets (git-ignored)
├── policies/                # IAM permission and trust policy JSON
├── screenshots/             # Evidence for reports and submission
├── scripts/
│   ├── cleanup/             # Explicit, opt-in cleanup utilities
│   ├── setup/               # Floci start/stop scripts
│   └── utilities/           # Verification and diagnostic helpers
├── templates/               # AWS CLI generated skeletons
├── docker-compose.yml       # Floci container + persistence config
└── README.md
```

---

## 4. Prerequisites

| Tool | Purpose |
|---|---|
| Docker Desktop / Docker Engine with Compose v2 | Runs the Floci container |
| Floci CLI | Floci management helpers |
| AWS CLI v2 | Talks to the emulator |
| `curl` | Health checks |
| `jq` | JSON parsing in scripts |
| Git | Version control |

Verify the toolchain:

```bash
docker --version
docker compose version
floci version
aws --version
jq --version
```

<details>
<summary>Installing AWS CLI v2 on macOS</summary>

```bash
curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o AWSCLIV2.pkg
sudo installer -pkg AWSCLIV2.pkg -target /
```

</details>

---

## 5. Quick Start

### Step 1 — Start Floci

From the repository root:

```bash
source configs/course.env
./scripts/setup/floci-up.sh
```

### Step 2 — Configure the `floci` profile

```bash
aws configure set aws_access_key_id     test                  --profile floci
aws configure set aws_secret_access_key test                  --profile floci
aws configure set region                us-east-1             --profile floci
aws configure set output                json                  --profile floci
aws configure set endpoint_url          http://localhost:4566 --profile floci
```

### Step 3 — Confirm you are talking to Floci, not real AWS

```bash
./scripts/utilities/whoami.sh
```

**Expected result**

```text
000000000000
```

> [!WARNING]
> If you see any account ID other than `000000000000`, **stop**. Your CLI is
> pointing at a real AWS account. Re-check `AWS_PROFILE` and the profile's
> `endpoint_url` before running anything else.

---

## 6. Daily Workflow

```bash
# 1. Start or resume the environment
source configs/course.env
./scripts/setup/floci-up.sh

# 2. Work using the floci profile
aws sts get-caller-identity
aws iam list-users

# 3. Pause the environment (state is kept)
./scripts/setup/floci-down.sh
```

---

## 7. Configuration

Shared settings live in [`configs/course.env`](configs/course.env).

| Variable | Default | Purpose |
|---|---|---|
| `AWS_PROFILE` | `floci` | AWS CLI profile used by the labs |
| `FLOCI_ENDPOINT` | `http://localhost:4566` | Local AWS-compatible endpoint |
| `AWS_REGION_COURSE` | `us-east-1` | Course region |
| `ACCOUNT_ID` | `000000000000` | Floci's local account ID |
| `PROJECT` | `usms` | Resource naming prefix |
| `FLOCI_STORAGE_MODE` | `hybrid` | Durable Floci storage mode |
| `FLOCI_HOST_DATA_DIR` | `$HOME/floci-data` | Host directory for persisted state |

Lab-specific names and ARNs are collected in
[`configs/lab-01.env`](configs/lab-01.env) once the Lab 01 resources exist.

---

## 8. Persistence Model

This project **intentionally avoids Floci's default memory-only mode**.

- The host directory `FLOCI_HOST_DATA_DIR` is bind-mounted into the container
  at `/app/data`.
- `scripts/setup/floci-up.sh` writes the **absolute** path into `.env`, because
  Docker Compose does not reliably expand `~` in volume paths.
- Storage mode defaults to `hybrid`; `persistent` and `wal` are also durable.

> [!TIP]
> If resources seem to vanish after a restart, run
> `./scripts/utilities/floci-storage-check.sh` first.
> See [Lab state disappeared](#lab-state-disappeared).

---

## 9. Safety Rules

> [!CAUTION]
> The commands below can destroy lab state or bypass the persistence setup.

| ❌ Do not run | Why |
|---|---|
| `docker compose down -v` | Deletes Docker volumes |
| `docker volume prune` | Deletes unfiltered volumes — use `scripts/cleanup/` instead |
| `floci start ...` | Starts a separate container outside this Compose setup |
| `rm -rf ~/floci-data` | Deletes all persisted Floci state |
| AWS CLI commands without checking the profile | May target real AWS |

**Golden rule:** run `./scripts/utilities/whoami.sh` before any AWS command.

---

## 10. Labs

| # | Topic | Location | Status |
|---:|---|---|---|
| 01 | IAM and environment setup | [`labs/lab-01-iam`](labs/lab-01-iam) | ✅ Complete |
| 02 | VPC | — | ⏳ Planned |

### Lab 01 — IAM Foundation

| Resource type | Names |
|---|---|
| Groups | `usms-admins`, `usms-developers`, `usms-auditors` |
| Users | `usms-admin-01`, `usms-dev-01`, `usms-audit-01` |
| Customer managed policies | `USMSDeveloperBase`, `USMSStudentDataReadWrite`, `USMSAssumeAppRoles`, `USMSLambdaBasic` |
| Roles | `usms-ec2-app-role`, `usms-lambda-exec-role`, `usms-developer-role` |
| Instance profile | `usms-ec2-app-profile` |

Also covered: STS assume-role practice with temporary credentials, and safe
access-key handling in git-ignored `outputs/` files.

**Checkpoint**

```text
account 000000000000
├── groups
│   ├── usms-admins      ── usms-admin-01
│   ├── usms-developers  ── usms-dev-01
│   └── usms-auditors    ── usms-audit-01
├── policies (customer managed) ×4
├── roles
│   ├── usms-ec2-app-role ── instance profile: usms-ec2-app-profile
│   ├── usms-lambda-exec-role
│   └── usms-developer-role
└── STS temporary credentials (outputs/, git-ignored)
```

**Verify**

```bash
./scripts/utilities/verify-lab-01.sh
```

---

## 11. IAM Policy Files

All reusable policy documents live in [`policies/`](policies).

**Permission policies**

| File | Purpose |
|---|---|
| `usms-developer-base-policy.json` | Base developer permissions |
| `usms-developer-base-policy-v2.json` | Updated developer policy version |
| `usms-student-data-rw-policy.json` | S3 read/write access to student data |
| `usms-assume-app-roles-policy.json` | Permission to assume USMS application roles |
| `usms-lambda-basic-policy.json` | Basic Lambda execution permissions |
| `usms-self-manage-credentials.json` | Inline policy for user credential self-management |

**Trust policies**

| File | Trusted principal |
|---|---|
| `trust-ec2.json` | EC2 service |
| `trust-lambda.json` | Lambda service |
| `trust-account-developers.json` | Human developers in the account |

Validate JSON before creating a policy:

```bash
python3 -m json.tool policies/usms-developer-base-policy.json > /dev/null
```

---

## 12. Secrets and Generated Outputs

[`outputs/`](outputs) holds generated command output, including temporary STS
responses and access keys. Everything in it is git-ignored except an optional
`.gitkeep`.

Ignored sensitive patterns include:

- `outputs/assumed-role.json`
- `outputs/usms-dev-01-access-key.json`
- `*-access-key.json`
- `*credentials*`

> [!IMPORTANT]
> Restrict permissions on any generated key file:
>
> ```bash
> chmod 600 outputs/usms-dev-01-access-key.json
> ```

---

## 13. Command Reference

| Task | Command |
|---|---|
| Start Floci | `./scripts/setup/floci-up.sh` |
| Stop Floci (keep state) | `./scripts/setup/floci-down.sh` |
| Check active identity | `./scripts/utilities/whoami.sh` |
| Check storage config | `./scripts/utilities/floci-storage-check.sh` |
| Verify Lab 01 | `./scripts/utilities/verify-lab-01.sh` |
| List local IAM policies | `aws iam list-policies --scope Local --output table` |
| List IAM groups | `aws iam list-groups --output table` |
| List IAM users | `aws iam list-users --output table` |

---

## 14. Troubleshooting

### Docker is not running

Start Docker Desktop, then:

```bash
./scripts/setup/floci-up.sh
```

### Port 4566 is already in use

```bash
lsof -i :4566
```

Stop the conflicting process or container, then start Floci again.

### A container named `floci` already exists

The setup script refuses to continue if a `floci` container exists that this
Compose project did not create. Remove it and restart:

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

1. Check container health:

   ```bash
   curl -sf http://localhost:4566/_floci/health
   docker compose ps
   ```

2. Check the profile:

   ```bash
   aws configure get endpoint_url --profile floci
   aws configure get region       --profile floci
   ```

### Lab state disappeared

```bash
./scripts/utilities/floci-storage-check.sh
```

Then confirm:

- [ ] `FLOCI_STORAGE_MODE` is `hybrid`, `persistent`, or `wal`
- [ ] `/app/data` is a bind mount
- [ ] `FLOCI_HOST_DATA_DIR` is an absolute host path
- [ ] `~/floci-data` exists and is not empty

---

## 15. Git Hygiene

| ✅ Track | 🚫 Ignore |
|---|---|
| Lab instructions | `.env` |
| Scripts | Local Floci state |
| Configuration templates | Generated access keys |
| IAM policy JSON | Temporary credentials |
| Screenshots required for submission | Command output under `outputs/` |

Pre-commit check:

```bash
git status --short
git check-ignore -q outputs/usms-dev-01-access-key.json && echo "access key is ignored"
git check-ignore -q .env && echo ".env is ignored"
```

---

## 16. Naming Conventions

| Item | Value |
|---|---|
| Project prefix | `usms-` |
| AWS profile | `floci` |
| Region | `us-east-1` |
| Local account ID | `000000000000` |
| Floci container | `floci` |
| Compose project | `floci-course` |
| Host state directory | `~/floci-data` |

---

> [!NOTE]
> This repository is for **local lab work only**. It is deliberately wired to the
> Floci endpoint and dummy credentials. Review and adapt every policy and
> command before using it against a real AWS account.