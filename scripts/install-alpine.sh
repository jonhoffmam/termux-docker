#!/data/data/com.termux/files/usr/bin/bash

echo -e"\n# Add docker host
eval $(ssh-agent)
ssh-add \$HOME/alpine/qemukey
export DOCKER_HOST=ssh://root@localhost:2222
DOCKER_INFO=$(docker info 2>&1)\n
if [[ \$DOCKER_INFO == *'error during connect'* ]]; then
  echo '-> Connecting to docker daemon, wait for Alpine VM to boot... (WAIT)'
  screen
  runAlpine
else
  echo '-> Docker running... (OK)'
fi" >> $PREFIX/etc/bash.bashrc

# Create and access VM folder
mkdir -p $HOME/alpine
cd $HOME/alpine

FREE_MEMORY=$(free -m | grep -oP '\d+' | head -n 1)
TOTAL_CPUS=$(nproc)

# Alpine installation
read -rp "-> What's the Alpine distro version for VM? [3.20.1] " ALPINE_VERSION
echo "-> You have $FREE_MEMORY of free memory..."
read -rp "-> What's the size of memory in megabytes(M) or gigabytes(G)? (515M / 1G / 2G /...) [512M] " AMOUNT_OF_MEMORY
echo "-> You have $TOTAL_CPUS CPUs..."
read -rp "-> What's the number of CPUs? (1 / 2 / 3 /...) [1] " NUMBER_OF_CPUS

ALPINE_VERSION="${ALPINE_VERSION:-3.20.1}"
ALPINE_ISO_NAME="alpine-virt-$ALPINE_VERSION-x86_64.iso"
ALPINE_ISO_LINK="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/$ALPINE_ISO_NAME"
AMOUNT_OF_MEMORY="${AMOUNT_OF_MEMORY:-512M}" #4G
NUMBER_OF_CPUS="${NUMBER_OF_CPUS:-1}" #4

# Download Alpine VM ISO
wget $ALPINE_ISO_LINK

# Create script to run Alpine VM
echo '#!/data/data/com.termux/files/usr/bin/bash' > $HOME/alpine/run_alpine.sh
echo -e "\nqemu-system-x86_64 \\
  -m $AMOUNT_OF_MEMORY \\
  -smp $NUMBER_OF_CPUS \\
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=tcp::9000-:9000,hostfwd=tcp::9443-:9443,hostfwd=tcp::5253-:53,hostfwd=udp::5253-:53,hostfwd=udp::6767-:67,hostfwd=tcp::8080-:8080,hostfwd=tcp::8180-:8180,hostfwd=tcp::8280-:8280 \\
  -device virtio-net,netdev=n1 \\
  -nographic \$HOME/alpine/alpine.qcow2 \\
  -monitor tcp:localhost:4444,server,nowait" >> $HOME/alpine/run_alpine.sh

chmod +x $HOME/alpine/run_alpine.sh

echo -e "\n# Aliases to run and connect SSH Alpine VM
alias runAlpine=\$HOME/alpine/run_alpine.sh
alias sshAlpine='ssh root@localhost -p 2222'" >> $PREFIX/etc/bash.bashrc

# Add a disk image
qemu-img create -f qcow2 alpine.qcow2 10G

# Install Alpine VM
qemu-system-x86_64 \
  -m $AMOUNT_OF_MEMORY \
  -smp $NUMBER_OF_CPUS \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device virtio-net,netdev=n1 \
  -cdrom $ALPINE_ISO_NAME \
  -nographic \
  -drive file=alpine.qcow2,format=qcow2

source $PREFIX/etc/bash.bashrc
