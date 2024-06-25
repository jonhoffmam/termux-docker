#!/data/data/com.termux/files/usr/bin/bash

# On Termux terminal
# Update, upgrade and install packages
./upgrade_packages.sh
pkg upgrade -y
pkg install root-repo -y
pkg install iproute2 openssh curl wget screen docker qemu-system-x86-64-headless qemu-utils -y

USER=$(whoami)

# Redefine user password
echo "-> Set a new password for $USER"
passwd

echo -e "\n# Clean screens dead
screen -wipe &> /dev/null" >> $PREFIX/etc/bash.bashrc

echo -e "\n# Verify and run SSHD
if pgrep sshd &> /dev/null; then
  echo '-> sshd running... (OK)'
else
  echo '-> sshd starting... (WAIT)'
  sshd
fi" >> $PREFIX/etc/bash.bashrc

IP_ADDRESS=$(ip route show | awk '{print $9}')
read -rp "-> Continue configuration on this terminal (1), or use ssh conection (2)? [1] " SETUP_CONTINUE

if [[ $SETUP_CONTINUE == "1" ]]; then
  ./install_alpine.sh
else
  source $PREFIX/etc/bash.bashrc
  echo -e "\n-> Use the following command to access Termux from your machine to continue the installation:\n       ssh $USER@$IP_ADDRESS -p 8022\n"
fi
