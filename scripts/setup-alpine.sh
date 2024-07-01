#!/bin/ash
#
# Adapted from https://www.shellscript.sh/examples/getopt/
#
set -euo pipefail

PASSWORD=""
TIMEZONE="America/Sao_Paulo"
KEYMAP="br br"
MANUAL=false
EMPTY_PASSWORD=false

main() {
  parsing_options $@
  check_all_params
  setup
  reboot_system
}

red() {
  echo -e "\e[91m$1\e[0m"
}

help() {
>&2 cat << EOF
Usage: $0 [options]
  Options:
    -h, --help                      Show this help message
    -m, --manual                    Set the configuration manually
    -e, --empty                     Empty root password
    -p, --password <your_password>  Set the password
    -t, --timezone <your_timezone>  Set the time zone
    -k, --keymap <your_keymap>      Set the keymap

  Option -e cannot be used with option -p.
  Option -p cannot be used with options -e, -m.
  Option -m cannot be used with options -p, -t, -k.

  Examples:
    $0 -m -e
    $0 -t 'America/Sao_Paulo' -p 'Password123' -k 'br'
    $0 --timezone 'America/Sao_Paulo' --password 'Password123' --keymap 'br'
EOF
exit 1
}

args=$(getopt -a -o hmep:t:k: --longoptions help,manual,empty,password:,timezone:,keymap: -- "$@")
eval set -- ${args}


check_param() {
  declare -A PARAM
  PARAM[OPT]=$1
  PARAM[ARG]=$2
  PARAM[EXAMPLE]=$3


  if [[ ${PARAM[ARG]} == -* ]]; then
    echo -e "\n\t$(red [ERROR]) Option '${PARAM[OPT]}' requires an argument!" >&2
    echo -e "\tExample:" >&2
    echo -e "\t\t $0 ${PARAM[OPT]} '${PARAM[EXAMPLE]}'\n" >&2
    exit 1
  fi
  
}

parsing_options() {
  while :
  do
    case $1 in
      -h | --help)      help                    ; shift   ;;
      -e | --empty)     EMPTY_PASSWORD=true     ; shift   ;;
      -m | --manual)    MANUAL=true             ; shift   ;;
      -k | --keymap)
        check_param $1 $2 'us'
        KEYMAP=$(echo "$2" | sed 's/\// /g')
        shift 2
        ;;
      -t | --timezone)
        check_param $1 $2 'America/New_York'
        TIMEZONE=$2
        shift 2
        ;;
      -p | --password)
        check_param $1 $2 'password123'
        PASSWORD=$2
        shift 2
        ;;
      # -- means the end of the arguments; drop this, and break out of the while loop
      --) shift; break ;;
      *)
        >&2 echo Unsupported option: $1
        help
        ;;
    esac
  done
}

check_all_params() {
  # Check if setup is manually with predefined password
  # ./setup-alpine.sh -m -p 'password'
  if [[ $MANUAL = true && $EMPTY_PASSWORD = false && -z "$PASSWORD" ]]; then
    echo -e "\n\t$(red [ERROR]) Unable to setup Alpine manually with predefined password!"
    echo -e "\tRemove predefined password to continue setup manually"
    echo "OR"
    echo -e "\tRemove manual flag to continue setup automatically with predefined password"
    echo
    exit 1
  fi

  # Check if setup has a predefined password and empty password flag
  # ./setup-alpine.sh -e -p 'password'
  if [[ $EMPTY_PASSWORD = true && -n "$PASSWORD" ]]; then
    echo -e "\n\t$(red [ERROR]) Unable to setup Alpine with predefined password and empty flag!"
    echo -e "\tRemove predefined password to continue setup without password"
    echo "OR"
    echo -e "\tRemove empty flag to continue setup automatically with predefined password"
    echo
    exit 1
  fi
}

create_answers() {
cat << EOF > answers_installation
KEYMAPOPTS="$KEYMAP"
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
hostname alpine
"
DNSOPTS="-d google.com -n 8.8.8.8"
TIMEZONEOPTS="-z $TIMEZONE"
PROXYOPTS="none"
APKREPOSOPTS="-c -1"
USEROPTS="alpine"
SSHDOPTS="-c openssh"
NTPOPTS="busybox"
DISKOPTS="-m sys -s 0 /dev/sda"
LBUOPTS="none"
APKCACHEOPTS="none"
EOF
}

set_password() {
  if [ -z $PASSWORD ]; then    
    read -rp "Please enter a new password for $USER: " PASSWORD
    
    set_password
  fi
}

setup() {
  if [[ $MANUAL = true && $EMPTY_PASSWORD = true ]]; then
    echo "Setup Alpine manually with empty password"
    setup-alpine -e
  
  elif [[ $MANUAL = false && $EMPTY_PASSWORD = true ]]; then
    echo "Setup Alpine automatically with empty password"
    create_answers
    yes "y" | setup-alpine -e -f answers_installation

  elif [[ $MANUAL = false && $EMPTY_PASSWORD = false ]]; then  
    echo "Setup Alpine automatically with predefined password"
    set_password
    create_answers
    echo -e "$PASSWORD\n$PASSWORD\ny" | setup-alpine -f answers_installation

  else
    echo "Setup Alpine manually"
    setup-alpine
  fi
}

reboot_system() {
  echo "Rebooting system..."
  reboot
}

main $@

exit 0