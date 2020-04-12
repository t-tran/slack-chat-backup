#!/bin/bash

mkdir -p meta messages log

function generate-digits() {
  local S=''
  for i in $(seq 1 $1) ; do
    S="$S$(( $RANDOM % 10 ))"
  done
  echo $S
}

###
### BEGIN: configuration
###

x_id=
x_version_ts=

team_name=
team_id=

cookie=
token=

###
### END: configuration
###
