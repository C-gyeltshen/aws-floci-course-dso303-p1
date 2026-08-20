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

#### ***1. Ephemeral Mode (Default)***
* **Behavior:** Data is stored strictly in container memory/tmpfs.
* **Persistence:** All IAM users, roles, policies, and S3 objects are completely wiped when the Docker container stops or restarts.
* **Use Case:** Quick isolated testing, stateless CI/CD runs, and quick experimentations where persistent state is unnecessary.

#### ***2. Persistent Mode***
* **Behavior:** Floci maps state data to a host directory using a Docker bind mount (configured via `FLOCI_HOST_DATA_DIR`).
* **Persistence:** AWS resources and configurations persist across container restarts and system reboots.

### Step 8 — Write docker-compose.yml and configs/course.env



