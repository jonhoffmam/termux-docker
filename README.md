# Termux Docker

## Install

### 1. Install git and expect packages

```bash
pkg install git -y && pkg install expect -y
```

### 2. Clone repository

```bash
git clone https://github.com/jonhoffmam/termux-docker.git && \
cd termux-docker/scripts
```

### 3. Run to start

```bash
bash start.sh
```

### 4. Setup interfaces and dns

```bash
setup-interfaces -ar && \
setup-dns -d google.com -n 8.8.8.8
```

### 5. Download setup-alpine script

```bash
wget https://raw.githubusercontent.com/jonhoffmam/termux-docker/main/scripts/setup-alpine.sh
```

## Access Termux via SSH

### 1. Create SSH key pair

```bash
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_termux_rsa
```

### 2. Copy public key to remote machine

```bash
ssh-copy-id -i $HOME/.ssh/id_termux_rsa.pub <USER_TERMUX>@<IP_TERMUX> -p 8022
```

### 3. Access

```bash
ssh -i $HOME/.ssh/id_termux_rsa <USER_TERMUX>@<IP_TERMUX> -p 8022
```
