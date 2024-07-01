# Termux Docker

This repository contains scripts to facilitate Docker installation on [Termux](https://termux.com/), a Linux terminal emulator for Android.

## Installation

The initial steps need to be executed directly in your Termux, but don't worry, after running the initial script, you can choose to continue the procedures directly on your Android device or via an SSH connection.

### Termux

#### 1. Execute the following commands in Termux to clone this repository and perform initial updates

```bash
pkg install git expect -y
```

#### 2. Execute the following command to clone the repository

```bash
git clone https://github.com/jonhoffmam/termux-docker.git && \
cd termux-docker/scripts
```

#### 3. Now execute the command to start

```bash
bash start.sh
```

#### 3.1 Wait for the packages to be installed and updated, and set a new password when prompted

>![image](https://github.com/jonhoffmam/termux-docker/assets/46982925/3f53d07d-38c3-4ac1-be60-0e8ad954323c)

#### 3.2 After the above command completes, you can choose to continue the installation in the Termux terminal or via SSH

>![image](https://github.com/jonhoffmam/termux-docker/assets/46982925/ed18877f-74d7-44c5-8c3c-12d38dc03ebc)

#### 3.3 If you prefer to continue the installation through your local computer, a message with the SSH command will be displayed

>![image](https://github.com/jonhoffmam/termux-docker/assets/46982925/8543398b-00d1-43f3-aff3-809e1361efcd)

#### 3.4 If you chose to continue the installation through your computer, execute the SSH command provided earlier and access the termux-docker/scripts folder and run the following command

```bash
./install-alpine.sh
```

When you run the above command, you will be asked some questions, such as Alpine version, amount of memory, and number of CPUs. If you prefer, use the options `-v -m -c` to provide this information beforehand, or `./install-alpine.sh -h` for more information.

### Alpine VM

After running the Alpine installation command, you will likely see the following screen where you should enter the login root to proceed.

>![image](https://github.com/jonhoffmam/termux-docker/assets/46982925/4fdb502e-07d0-4429-86bc-c11246a3030c)

#### 1. Execute the commands below to configure interfaces and DNS

```bash
setup-interfaces -ar && \
setup-dns -d google.com -n 8.8.8.8
```

#### 2. Download setup-alpine script

```bash
wget https://raw.githubusercontent.com/jonhoffmam/termux-docker/main/scripts/setup-alpine.sh
```

#### 3. Execute the command below to configure Alpine

```bash
ash setup-alpine.sh
```

#### 4. Download install-docker script

```bash
wget https://raw.githubusercontent.com/jonhoffmam/termux-docker/main/scripts/install-docker.sh
```

#### 5. Execute the command to install Docker

```bash
ash ./install-docker.sh
```

### Access Termux via SSH

Instructions for accessing Termux via SSH with a key

#### 1. Create SSH key pair

```bash
ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_termux_rsa
```

#### 2. Copy public key to remote machine

```bash
ssh-copy-id -i $HOME/.ssh/id_termux_rsa.pub <USER_TERMUX>@<IP_TERMUX> -p 8022
```

#### 3. Access

```bash
ssh -i $HOME/.ssh/id_termux_rsa <USER_TERMUX>@<IP_TERMUX> -p 8022
```
