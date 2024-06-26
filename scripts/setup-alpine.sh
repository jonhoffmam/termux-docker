#!/bin/bash

TIMEZONE="America/Sao_Paulo"
KEYMAP="br"
MANUAL=false

# Help function for command line
help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -h, --help                      Show this help message"
  echo "  -m, --manual                    Use this option to manually set the answers"
  echo "  -t, --timezone <your_timezone>  Set the time zone"
  echo "  -p, --password <your_password>  Set the password"
  echo "  -k, --keymap <your_keymap>      Set the keymap"
  echo
  echo "Examples:"
  echo "  $0 -m"
  echo "  $0 -t 'America/Sao_Paulo' -p 'Password123' -k 'br'"
  echo "  $0 --timezone 'America/Sao_Paulo' --password 'Password123' --keymap 'br'"
  exit 1
}

# Parsing command line options
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -m | --manual)
      MANUAL=true
      ;;
    -t | --timezone)
      TIMEZONE="$2"
      shift
      ;;
    -p | --password)
      PASSWORD="$2"
      shift
      ;;
    -k | --keymap)
      KEYMAP="$2"
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


create_answers() {
  ALPINE_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/alpine-release)

  cat << EOF > answers_alpine_install
  KEYMAPOPTS="$KEYMAP $KEYMAP"
  HOSTNAMEOPTS="-n alpine"
  INTERFACESOPTS="auto lo
  iface lo inet loopback

  auto eth0
  iface eth0 inet dhcp
  hostname alpine
  "
  DNSOPTS="-d google.com 8.8.8.8 8.8.4.4"
  TIMEZONEOPTS="$TIMEZONE"
  PROXYOPTS="none"
  APKREPOSOPTS="http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community"
  USEROPTS="alpine"
  SSHDOPTS="-c openssh"
  NTPOPTS="-c busybox"
  DISKOPTS="-v -m sys -s 0 /dev/sda"
  LBUOPTS="none"
  APKCACHEOPTS="none"
EOF
}

set_password() {
  if [ -z $PASSWORD ]; then    
    read -rp "Please, enter a new password for $USER: " PASSWORD
    
    set_password
  fi
}

if [ $MANUAL = false ]; then
  set_password
  create_answers

  echo -e "$PASSWORD\n$PASSWORD\ny" | setup-alpine -f answers_alpine_install

else
  setup-alpine
fi


apk update
apk add docker

service docker start

poweroff
exit
