#!/bin/bash

SLACK_BACKUP_CONFIG=${SLACK_BACKUP_CONFIG:-"config.sh"}
source common.sh
source "$SLACK_BACKUP_CONFIG"

if [[ $SLACK_BACKUP_DEBUG -gt 0 ]]; then
  set -x
fi

c_channel=$1

for f in messages/$team_name/*/$c_channel/*.json; do
  echo "reading $f"
  t=$(basename $(dirname $(dirname $f)))
  touch log/$team_name/$t/$c_channel/purge.done
  for c_ts in $(jq -r '.messages[].ts' $f | sort); do
    if [[ $(grep -c "^$c_ts$" log/$team_name/$t/$c_channel/purge.done) -gt 0 ]]; then
      echo -n -
      continue
    fi
    x_ts=$(gdate +%s.%3N)
    boundary='---------------------------'$(generate-digits 29)
    while [[ 1 ]]; do
      make-request "https://$team_name.slack.com/api/chat.delete?_x_id=$x_id-$x_ts&slack_route=$team_id&_x_version_ts=$x_version_ts" \
         -H 'Content-Type: multipart/form-data; boundary='$boundary \
         --data-binary $'--'$boundary$'\r\nContent-Disposition: form-data; name="channel"\r\n\r\n'$c_channel$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="ts"\r\n\r\n'$c_ts$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="token"\r\n\r\n'$token$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_reason"\r\n\r\nanimateAndDeleteMessageApi\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_mode"\r\n\r\nonline\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_sonic"\r\n\r\ntrue\r\n--'$boundary$'--\r\n' \
         >log/$team_name/$t/$c_channel/purge.json 2>log/$team_name/$t/$c_channel/purge.log
      status_code=$(cat log/$team_name/$t/$c_channel/purge.log | grep "^< HTTP/" | awk '{ print $3 }')
      if [[ $status_code -eq 200 ]]; then
        echo "$c_ts" >> log/$team_name/$t/$c_channel/purge.done
        echo -n .
        break
      else
        echo -n +
        sleep 1
      fi
    done
  done
  echo
done
exit

