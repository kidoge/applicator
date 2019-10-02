PROMPT_RESPONSE_OVERWRITE=1
PROMPT_RESPONSE_MERGE=2
PROMPT_RESPONSE_SKIP=3
PROMPT_OPTION_TEXT="(O)verwrite, (M)erge, or (S)kip: "

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

resolve_repo() {
  local input="$1"
  if [[ "$input" =~ ":" ]]; then
    local user="$(echo $input | sed -En "s/^(.*):.*/\1/p")"
    local repo="$(echo $input | sed -En "s/^.*:(.*)/\1/p")"
  else
    local user="$1"
    local repo="applicator-config"
  fi

  echo "https://github.com/$user/$repo"
}

make_backup() {
  local destination="$1"

  # If modfiying existing config file, make a backup first
  local increment=0
  local backup_basename=${destination}.bak
  local backup=${backup_basename}

  while [ -f $backup ]; do
    if diff ${backup} ${destination} &>/dev/null; then
      echo "Skipping creating backup... Identical backup found at: ${backup}"
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

promptOverwriteOrMerge() {
  local file="$1"

  printf "A file already exists at: $1.\n${PROMPT_OPTION_TEXT}"
  while : ; do
    read char
    case "$char" in
      "o" | "O")
        return $PROMPT_RESPONSE_OVERWRITE
        ;;
      "m" | "M")
        return $PROMPT_RESPONSE_MERGE
        ;;
      "s" | "S")
        return $PROMPT_RESPONSE_SKIP
        ;;
    esac
    printf "Invalid input.\n${PROMPT_OPTION_TEXT}"
  done
}

install_config_file() {
  local file="$1"
  local destination="$2"

  if [ ! -f $destination ]; then
    cp ${file} ${destination}
    echo_if_verbose "A new file created at: ${destination}"
  else
    promptOverwriteOrMerge $destination
    local result=$?
    case "$result" in
      $PROMPT_RESPONSE_OVERWRITE)
        make_backup $destination
        cp ${file} ${destination}
        ;;
      $PROMPT_RESPONSE_MERGE)
        make_backup $destination
        vimdiff $destination $file
        ;;
      $PROMPT_RESPONSE_SKIP)
        # Do nothing...
        ;;
    esac
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

