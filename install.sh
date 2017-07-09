#!/bin/bash

CONFIG_INSTALL_START="INSTALL_SH_CONFIG_INSERTION_START"
CONFIG_INSTALL_END="INSTALL__SH_CONFIG_INSERTION_END"

VERBOSE=0
LINE_PREFIX=""

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

die_with_help() {
  printf 'ERROR: %s\n' "$1" >&2
  echo "Try 'bash install.sh --help' for more information."
  exit 1
}

show_help() {
  cat << EOF
Usage: bash install.sh [OPTION]... [TARGET]...
  -h, --help, -?    show help
  -v, --verbose     verbose output
EOF
  echo $help
}

echo_if_verbose() {
  if [ ! -z $VERBOSE ]; then
    echo $@
  fi
}

first_char() {
    file="$1"
    head -c 1 $file
}

recursion_check() {
    file = "$1"
}

install_config() {
  file="$1"
  destination="${HOME}/.$(basename ${file})"
  backup=${destination}.bak
  cp ${destination} ${backup}
  if [ $? -eq 0 ]; then
    echo_if_verbose "Backup created at: ${backup}"
  else
    die "Backup creation failed: ${backup}"
  fi

  if [ ! recursion_check $file ]; then
    die "Start/end flag detected in config."
  fi

  sed "/${CONFIG_INSTALL_START}/,$ d" ${backup} > ${destination}
  if [ -z $LINE_PREFIX]; then
      LINE_PREFIX=$(first_char $file)
  fi
  echo ${LINE_PREFIX}${CONFIG_INSTALL_START} >> ${destination}
  cat ${file} >> ${destination}
  echo ${LINE_PREFIX}${CONFIG_INSTALL_END} >> ${destination}
  sed "1,/${CONFIG_INSTALL_END}/ d" $backup >> ${destination}

  vimdiff ${destination} ${backup}
  if [ ! $? -eq 0 ]; then
    echo_if_verbose "Rolling back changes for: ${destination}"
    cp ${backup} ${destination}
  fi
}

main() {

# Handle arguments
# Taken from: http://mywiki.wooledge.org/BashFAQ/035
  while :; do
    case $1 in
    -h|-\?|--help)
      show_help
      ;;
    -v|--VERBOSE)
      VERBOSE=1
      ;;
    -p|--prefix)
      LINE_PREFIX=$2
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      die_with_help "Unknown option: $1"
      ;;
    *)
      break;
      ;;
    esac

    shift
  done

  if [ -z "$1" ]; then
    die_with_help 'TARGET must be specified for installation'
  fi

# Find list of files

  input=( )

  if [ -d "$1" ]; then
    if [ ! -z "$2" ]; then
      die_with_help 'In directory mode, only one directory can be installed at a time.' 
    fi
    for f in $1/*; do
      if [ ! -d "$f" ]; then
        input+=("$f")
      fi
    done
  else
    while [ "$1" ]; do
      input+=("$1")
      shift
    done
  fi

  for f in ${input[@]}; do
      install_config $f
  done
}

main "$@"
