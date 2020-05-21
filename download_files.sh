#!/bin/bash

SLACK_BACKUP_CONFIG=${SLACK_BACKUP_CONFIG:-"config.sh"}
source common.sh
source "$SLACK_BACKUP_CONFIG"

if [[ $SLACK_BACKUP_DEBUG -gt 0 ]]; then
  set -x
fi

for c in messages/$team_name/*/*; do
  echo -n "downloading files in chat: $c "
  fcount=0
  for f in $c/*.json; do
    channel=$(basename $(dirname $f))
    for a in $(jq -r '.messages[]|select(.files!=null)|.files[]|select(.url_private_download!=null)|.url_private_download' $f); do
      p=$(echo $a | awk -F'slack.com/files-pri/' '{ print $2 }')
      mkdir -p files/$team_name/$(dirname $p)
      if [[ -f files/$team_name/$p ]]; then
        echo -n .
        continue
      fi
      while [[ 1 ]]; do
        curl -sv "$a" \
           -H "User-Agent: $USER_AGENT" \
           -H 'Accept: */*' \
           -H 'Accept-Language: en-US,en;q=0.5' \
           -H 'Origin: https://app.slack.com' \
           --cookie "cookies/$team_name.jar" \
           >files/$team_name/$p 2>log/$team_name/download_files.log
        let status_code=$(cat log/$team_name/download_files.log | grep "^< HTTP/" | awk '{ print $3 }')0/10
        if [[ $status_code -eq 200 ]]; then
          let fcount=$fcount+1
          echo -n .
          break
        else
          echo -n +
          sleep 1
        fi
      done
    done
  done
  echo $fcount
done
exit

