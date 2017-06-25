#!/bin/bash

input=""
verbose=""
force=""

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

show_help() {
  echo "-i <file> install file"
  echo "-h show help message"
}

main() {

# Handle arguments
# Taken from: http://mywiki.wooledge.org/BashFAQ/035
  while :; do
    case $1 in
    -h|-\?|--help)
      show_help
      ;;
    -v|--verbose)
      verbose=1
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "ERROR: Unknown option: $1"
      ;;
    *)
      break;
      ;;
    esac

    shift
  done

  if [ -z "$1" ]; then
    die 'ERROR: a directory or files must be specified for installation'
  fi

# Find list of files

  input=( )

  if [ -d "$1" ]; then
    if [ ! -z "$2" ]; then
      die 'ERROR: In directory mode, only one directory can be installed at a time.' 
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

  echo $verbose
  echo $force
  for f in ${input[@]}; do
    if [ ! -z $verbose ]; then
      echo FILE: $f
    fi
  done
}

main "$@"
