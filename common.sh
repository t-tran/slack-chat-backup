#!/bin/bash

mkdir -p meta messages files log

function generate-digits() {
  local S=''
  for i in $(seq 1 $1) ; do
    S="$S$(( $RANDOM % 10 ))"
  done
  echo $S
}

if [ "$(uname)" = "Linux" ] &&
    ! command -v gdate >/dev/null &&
    command -v date >/dev/null; then

    gdate() {
        date "$@"
    }
fi
