# Termux Docker

## Install

### 1. Install git and expect packages

```bash
pkg install git -y && pkg install expect -y
```

### 2. Clone repository

```bash
git clone https://github.com/jonhoffmam/termux-docker.git && \
cd termux-docker/scripts && \
chmod +x *.sh
```

### 3. And run

```bash
./start.sh
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
