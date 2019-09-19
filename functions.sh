die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

die_with_help() {
  printf 'ERROR: %s\n' "$1" >&2
  echo "Try 'bash applicator --help' for more information."
  exit 1
}

echo_if_verbose() {
  if [ ! -z $VERBOSE ]; then
    echo $@
  fi
}

make_backup() {
  local destination="$1"

  # If modfiying existing config file, make a backup first
  local increment=0
  local backup_basename=${destination}.bak
  local backup=${backup_basename}

  while [ -f $backup ]; do
    if diff ${backup} ${destination} &>/dev/null; then
      echo "Identical backup found at: ${backup}"
      return 0
    fi
    backup="${backup_basename}.${increment}"
    ((increment++))
  done
  cp ${destination} ${backup}
  if [ $? -eq 0 ]; then
    echo_if_verbose "Backup created at: ${backup}"
  else
    die "Backup creation failed: ${backup}"
  fi
}

create_new_file() {
  local file="$1"
  local destination="$2"
  local line_prefix="$3"

  # If file does not exist, create a new one
  echo ${line_prefix}${CONFIG_INSTALL_START} >> ${destination}
  cat ${file} >> ${destination}
  echo ${line_prefix}${CONFIG_INSTALL_END} >> ${destination}
  echo_if_verbose "Existing file not found. File created at: ${destination}"
}

confirm_diff() {
  local file="$1"
  local backup="$2"
  if [ $FORCE -eq 0 ]; then
    vimdiff ${destination} ${backup}
    if [ ! $? -eq 0 ]; then
      echo_if_verbose "Rolling back changes for: ${destination}"
      cp ${backup} ${destination}
    fi
  fi
}

update_existing_file() {
  local file="$1"
  local destination="$2"
  local line_prefix="$3"

  local backup=$(make_backup $file)

  sed "/${CONFIG_INSTALL_START}/,$ d" ${backup} > ${destination}
  echo ${line_prefix}${CONFIG_INSTALL_START} >> ${destination}
  cat ${file} >> ${destination}
  echo ${line_prefix}${CONFIG_INSTALL_END} >> ${destination}
  sed "1,/${CONFIG_INSTALL_END}/ d" $backup >> ${destination}
  echo_if_verbose "File updated at: ${destination}"

  if diff ${destination} ${backup}; then
    echo "No change detected for file: ${destination}"
  else
    confirm_diff ${destination} ${backup}
  fi
}

install_config_file() {
  local file="$1"
  local destination="${INSTALL_DIR}/$(basename ${file})"

  # Sanity check on input
  if detect_already_applied $file; then
    die "This file has already been applicated"
  fi

  local line_prefix=$(get_comment_prefix $file)

  if [ ! -f $destination ]; then
    create_new_file $file $destination $line_prefix
  else
    update_existing_file $file $destination $line_prefix
  fi
}

show_help() {
  cat << EOF
Usage: bash applicator [OPTION]... [TARGET]...
  -h, --help, -?    show help
  -v, --verbose     verbose output
  -f, --force       apply all changes without review
  -d                where to apply config files, defaults to home directory
EOF
  echo $help
}

