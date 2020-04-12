#!/bin/bash

source config.sh

MAX_THREADS=30
for t in ims mpims channels; do
  IDS=$(cat meta/boot.json | jq -r '.'$t'[].id')
  for i in $IDS; do
    ./conversation.sh $t $i &
    # max 5 threads
    while [[ true ]]; do
      RUNNING=$(jobs | wc -l)
      if [[ $RUNNING -lt $MAX_THREADS ]]; then
        break
      fi
      sleep 1
    done
  done
done

while [[ true ]]; do
  RUNNING=$(jobs | wc -l)
  if [[ $RUNNING -eq 0 ]]; then
    break
  fi
  sleep 1
done

exit

