#!/bin/bash

source common.sh

function usage() {
  cat <<EOF
Usage: $0 [command] [options]

COMMAND:
    boot        Download account info and related users profile (meta data)
    sync        Download all messages (requires existing meta data)
    test        Attempt to check system compatibility *DEFAULT*
    all         Perform all commands above in listed order

OPTIONS:
    -c|--config Path to config file. Default: config.sh
    -d|--debug  Enable debug. Extremely verbose.
    -h|--help   Print this help.
EOF
}

function system_check() {
  uname=$(uname)
  required_commands="curl gdate jq"
  if [[ "X$uname" == "XDarwin" ]]; then
    echo "You may want to brew install: 'coreutils' and 'jq'"
  fi
  echo "Checking.."
  for r in $required_commands; do
    type $r || exit 1
  done
}

#
##
### main()
valid_commands="boot sync all test"
comm=$(echo $1 | tr '[:upper:]' '[:lower:]')
valid=0
for v in $valid_commands ; do
  if [[ "X$v" == "X$comm" ]]; then
    valid=1
  fi
done

if [[ $valid -gt 0 ]]; then
  shift
else
  comm="test"
fi

export SLACK_BACKUP_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd $SLACK_BACKUP_ROOT

export SLACK_BACKUP_CONFIG="config.sh"
export SLACK_BACKUP_DEBUG=0
while [[ $1 ]]; do
  case "$1" in
    -c|--config)               SLACK_BACKUP_CONFIG="$2"; shift ;;
    -d|--debug)                SLACK_BACKUP_DEBUG=1; set -x ;;
    -h|--help|*)               usage; exit ;;
  esac
  shift
done

if [[ ! -f "$SLACK_BACKUP_CONFIG" ]]; then
  echo "Config '$SLACK_BACKUP_CONFIG' not found"
  exit
fi

case "$comm" in
  boot)       ./boot.sh ;;
  sync)       ./jobs.sh ;;
  test)       system_check ;;
  all)        system_check; ./boot.sh ; ./jobs.sh ;;
esac
