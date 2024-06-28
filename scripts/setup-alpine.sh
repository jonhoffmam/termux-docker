#!/bin/ash

TIMEZONE="America/Sao_Paulo"
KEYMAP="br"
MANUAL=false
EMPTY_PASSWORD=false

main() {
  parsing_options "$@"
  check_all_params
  setup
  reboot_system
}

red() {
  echo -e "\e[91m$1\e[0m"
}

help() {
  echo "Usage: $0 [options]"
  echo
  echo "Options:"
  echo "  -h, --help                      Show this help message"
  echo "  -m, --manual                    Set the configuration manually"
  echo "  -e, --empty                     Empty root password"
  echo "  -p, --password <your_password>  Set the password"
  echo "  -t, --timezone <your_timezone>  Set the time zone"
  echo "  -k, --keymap <your_keymap>      Set the keymap"
  echo
  echo "Option -p cannot be used with options -e, -m."
  echo
  echo "Examples:"
  echo "  $0 -m -e"
  echo "  $0 -t 'America/Sao_Paulo' -p 'Password123' -k 'br'"
  echo "  $0 --timezone 'America/Sao_Paulo' --password 'Password123' --keymap 'br'"
  exit 1
}

check_param() {
  declare -A PARAM
  PARAM[VALUE]=$1
  PARAM[NAME]=$2
  PARAM[EXAMPLE]=$3
  
  if [[ -z ${PARAM[VALUE]} ]]; then
    echo -e "\n\t$(red [ERROR]) You must specify a ${PARAM[NAME]}!"
    echo -e "\tExample:"
    echo -e "\t\t $0 $key '${PARAM[EXAMPLE]}'\n"
    exit 1
  fi
}

check_all_params() {
  # Check if setup is manually with predefined password
  # ./setup-alpine.sh -m -p 'password'
  if [[ $MANUAL = true && $EMPTY_PASSWORD = false && -n $PASSWORD ]]; then
    echo -e "\n\t$(red [ERROR]) Unable to setup Alpine manually with predefined password!"
    echo -e "\tRemove predefined password to continue setup manually"
    echo "OR"
    echo -e "\tRemove manual flag to continue setup automatically with predefined password"
    echo
    exit 1
  fi

  # Check if setup has a predefined password and empty password flag
  # ./setup-alpine.sh -e -p 'password'
  if [[ $EMPTY_PASSWORD = true && -n $PASSWORD ]]; then
    echo -e "\n\t$(red [ERROR]) Unable to setup Alpine with predefined password and empty flag!"
    echo -e "\tRemove predefined password to continue setup without password"
    echo "OR"
    echo -e "\tRemove empty flag to continue setup automatically with predefined password"
    echo
    exit 1
  fi
}

parsing_options() {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -e | --empty)
        EMPTY_PASSWORD=true
        ;;
      -m | --manual)
        MANUAL=true
        ;;
      -k | --keymap)
        check_param "$2" "keymap" "us"
        if [[ $(echo "$2" | wc -w) -eq 2 ]]; then
          KEYMAP="$2"
        else
          KEYMAP="$2 $2"
        fi
        shift
        ;;
      -t | --timezone)
        check_param "$2" "timezone" "America/Sao_Paulo"
        TIMEZONE="$2"
        shift
        ;;
      -p | --password)
        check_param "$2" "password" "password123"
        PASSWORD="$2"
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
DNSOPTS="-d google.com 8.8.8.8 8.8.4.4"
TIMEZONEOPTS="$TIMEZONE"
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

main "$@"
