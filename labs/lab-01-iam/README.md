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



