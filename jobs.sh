#!/bin/bash

source common.sh
source "$SLACK_BACKUP_CONFIG"

trap "for i in \$(jobs -p); do kill \$i; done; exit" SIGINT SIGHUP

echo "Job manager - start : $MAX_THREADS jobs at a time!"

for t in ims mpims channels; do
  IDS=$(cat meta/$team_name/boot.json | jq -r '.'$t'[].id')
  for i in $IDS; do
    # check if we can skip archived channels since they should not have any new messages
    if [[ "X$t" == "Xchannels" ]]; then
      if [[ $SKIP_ARCHIVED_CHANNELS -gt 0 ]]; then
        is_archived=$(cat meta/$team_name/boot.json | jq -r $'.channels[]|select(.id=="'$i$'")|.is_archived')
      fi
    fi
    ./conversation.sh $t $i &
    while [[ true ]]; do
      RUNNING=$(jobs | grep -c 'Running')
      if [[ $RUNNING -lt $MAX_THREADS ]]; then
        break
      fi
      sleep 1
    done
  done
done

counter=0
while [[ true ]]; do
  RUNNING=$(jobs | grep -c 'Running')
  if [[ $RUNNING -eq 0 ]]; then
    break
  fi
  if [[ $counter -gt 30 ]]; then
    echo "Job manager - checkpoint : $RUNNING jobs running.."
    counter=0
  fi
  sleep 1
  let counter=$counter+1
done

echo "Job manager - finish : All jobs completed!"
