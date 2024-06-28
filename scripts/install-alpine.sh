#!/data/data/com.termux/files/usr/bin/bash

ssh-keygen -t rsa -b 4096 -f $HOME/.ssh/id_alpine_rsa

cat << EOF > $HOME/.ssh/config
Host alpine
  HostName localhost
  User root
  IdentityFile ~/.ssh/id_alpine_rsa
  Port 2222
  ForwardAgent yes
  Compression yes
EOF

# Create and access VM folder
mkdir -p $HOME/alpine
cd $HOME/alpine

declare -A DEFAULT

DEFAULT[ALPINE_VERSION]="3.20.1"
DEFAULT[AMOUNT_OF_MEMORY]="512"
DEFAULT[NUMBER_OF_CPUS]="1"

help() {
  echo -e "Use: $0 [-v | --version <alpine_version>] [-m | --memory <amount_memory>] [-c | --cpu <cpus>]\n"
  echo "Examples:"
  echo "  $0 -v '3.20.1' -m '515M' -c '2'"
  echo "  $0 --version '3.20.1' --memory '2G' --cpu '4'"
  exit 1
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -v | --version)
      ALPINE_VERSION="$2"
      shift
      ;;
    -m | --memory)
      AMOUNT_OF_MEMORY="$2"
      shift
      ;;
    -c | --cpu)
      NUMBER_OF_CPUS="$2"
      shift
      ;;
    -h | --help)
      help
      ;;
    *)
      help
      ;;
  esac
  shift
done

red() {
  echo -e "\e[91m$1\e[0m"
}

blue() {
  echo -e "\e[94m$1\e[0m"
}

# Alpine installation

version() {
  if [ -z $ALPINE_VERSION ]; then
    read -rp $'\nWhat\'s the Alpine distro version for VM? ['"${DEFAULT[ALPINE_VERSION]}"'] ' ALPINE_VERSION
  fi

  ALPINE_VERSION="${ALPINE_VERSION:-${DEFAULT[ALPINE_VERSION]}}"
}

memory() {
  FREE_MEMORY=$(free -m | grep -oP '\d+' | head -n 1)

  if [ -z $AMOUNT_OF_MEMORY ]; then
    echo "You have $(red ${FREE_MEMORY}M) of free memory..."
    read -rp $'\tWhat\'s the size of memory in megabytes(M) or gigabytes(G)? (515M / 1G / 2G /...) ['"${DEFAULT[AMOUNT_OF_MEMORY]}"'M] ' AMOUNT_OF_MEMORY
  fi

  AMOUNT_OF_MEMORY="${AMOUNT_OF_MEMORY:-${DEFAULT[AMOUNT_OF_MEMORY]}}" #4G

  if [ $AMOUNT_OF_MEMORY -gt $FREE_MEMORY ]; then
    echo -e "\n$(red '[ERROR]') Amount of memory greater than total!\n"

    AMOUNT_OF_MEMORY=""
    memory
  fi

}

cpus() {
  TOTAL_CPUS=$(nproc)

  if [ -z $NUMBER_OF_CPUS ]; then
    echo "You have $(red $TOTAL_CPUS) CPUs..."
    read -rp $'\tHow many CPUs do you want to use? (1 / 2 / 3 /...) ['"${DEFAULT[NUMBER_OF_CPUS]}"'] ' NUMBER_OF_CPUS
  fi

  NUMBER_OF_CPUS="${NUMBER_OF_CPUS:-1}" #4

  if [ $NUMBER_OF_CPUS -gt $TOTAL_CPUS ]; then
    echo -e "\n$(red '[ERROR]') Number of CPUs greater than total!\n"

    NUMBER_OF_CPUS=""
    cpus
  fi
}

print_info() {
  echo -e "\n$(blue Alpine:) $ALPINE_VERSION"
  echo -e "$(blue Memory:) $AMOUNT_OF_MEMORY"
  echo -e "$(blue CPUs:) $NUMBER_OF_CPUS\n"
}

version
cpus
memory
print_info


# Download Alpine VM ISO
ALPINE_ISO_NAME="alpine-virt-$ALPINE_VERSION-x86_64.iso"
ALPINE_ISO_LINK="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/$ALPINE_ISO_NAME"

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

# Create a disk image
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

echo -e "\n# Add docker host
eval \$(ssh-agent)
ssh-add \$HOME/.ssh/id_alpine_rsa
export DOCKER_HOST=ssh://root@localhost:2222
DOCKER_INFO=\$(docker info 2>&1)\n
if [[ \$DOCKER_INFO == *'error during connect'* ]]; then
  echo '-> Connecting to docker daemon, wait for Alpine VM to boot... (WAIT)'
  screen -S alpine -dm bash -c '$HOME/alpine/run_alpine.sh'
else
  echo '-> Docker running... (OK)'
fi" >> $PREFIX/etc/bash.bashrc
