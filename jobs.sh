#!/bin/bash

source common.sh
source "$SLACK_BACKUP_CONFIG"

trap "for i in \$(jobs | awk -F']' '{ print \$1 }' | tr -d '['); do kill %\$i; done" EXIT SIGINT SIGHUP

for t in ims mpims channels; do
  IDS=$(cat meta/boot.json | jq -r '.'$t'[].id')
  for i in $IDS; do
    ./conversation.sh $t $i &
    # max 5 threads
    while [[ true ]]; do
      RUNNING=$(jobs | grep -c 'Running')
      if [[ $RUNNING -lt $MAX_THREADS ]]; then
        break
      fi
      sleep 1
    done
  done
done

while [[ true ]]; do
  RUNNING=$(jobs | grep -c 'Running')
  if [[ $RUNNING -eq 0 ]]; then
    break
  fi
  echo "$RUNNING jobs running.."
  sleep 1
done
