#!/bin/bash

source common.sh
source "$SLACK_BACKUP_CONFIG"

if [[ $# -lt 1 ]]; then
  exit
fi

t=$1
shift

ignored_ids=""
if [[ "X$t" == "Xims" ]]; then
  ignored_ids=$ims_ignored
fi
if [[ "X$t" == "Xmpims" ]]; then
  ignored_ids=$mpims_ignored
fi
if [[ "X$t" == "Xchannels" ]]; then
  ignored_ids=$channels_ignored
fi

for i in $@; do
  ignore_matched=0
  for a in $ignored_ids; do
    if [[ "X$i" == "X$a" ]]; then
      ignore_matched=1
      break
    fi
  done
  if [[ $ignore_matched -gt 0 ]]; then
    echo "$t - $i : job skipped!"
    continue
  fi
  echo "$t - $i : job started!"

  latest=''

  mkdir -p messages/$team_name/$t/$i
  mkdir -p log/$team_name/$t/$i
  output=latest
  has_more=true

  while [[ "X$has_more" == "Xtrue" ]]; do
    x_ts=$(gdate +%s.%3N)
    boundary='---------------------------'$(generate-digits 29)
    curl -sv "https://$team_name.slack.com/api/conversations.history?_x_id=$x_id-$x_ts&slack_route=$team_id&_x_version_ts=$x_version_ts" \
    -H "User-Agent: $USER_AGENT" \
    -H 'Accept: */*' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Content-Type: multipart/form-data; boundary='$boundary \
    -H 'Origin: https://app.slack.com' \
    -H "Cookie: $cookie" \
    --data-binary $'--'$boundary$'\r\nContent-Disposition: form-data; name="channel"\r\n\r\n'$i$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="limit"\r\n\r\n42\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="ignore_replies"\r\n\r\ntrue\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="include_pin_count"\r\n\r\ntrue\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="inclusive"\r\n\r\ntrue\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="no_user_profile"\r\n\r\ntrue\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="latest"\r\n\r\n'$latest$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="token"\r\n\r\n'$token$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_reason"\r\n\r\nmessage-pane/requestHistory\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_mode"\r\n\r\nonline\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_sonic"\r\n\r\ntrue\r\n--'$boundary$'--\r\n' \
    >messages/$team_name/$t/$i/$output.json 2>log/$team_name/$t/$i/$output.log

    status_code=$(cat log/$team_name/$t/$i/$output.log | grep "^< HTTP/" | awk '{ print $3 }')
    if [[ $status_code -ne 200 ]]; then
      # try again
      if [[ $status_code -eq 429 ]]; then
        echo "$t - $i : $output .. rate-limited. re-trying..."
        sleep 3
      else
        echo "$t - $i : $output .. non-200 code. re-trying..."
      fi
      sleep 0.2
    else
      jq . messages/$team_name/$t/$i/$output.json >/dev/null 2>&1
      if [[ $? -gt 0 ]] || [[ ! -s messages/$team_name/$t/$i/$output.json ]]; then
        echo "$t - $i : $output .. invalid json. re-trying..."
      else
        echo "$t - $i : $output .. ok"
        newest=$(basename $(ls -1 messages/$team_name/$t/$i/ 2>/dev/null | sort | grep "$output.json" -B1 | head -n 1) .json || echo 0)
        has_more=$(cat messages/$team_name/$t/$i/$output.json | jq -r .has_more)
        latest=$(cat messages/$team_name/$t/$i/$output.json | jq -r '.messages[].ts' | sort -n | head -n 1)
        output=$latest
        newest_done=0
        if [[ "X$newest" > "X$output" ]] || [[ "X$newest" == "X$output" ]]; then
          newest_done=1
        fi
        if [[ $newest_done -gt 0 ]]; then
          while [[ true ]]; do
            oldest=$(cat messages/$team_name/$t/$i/$newest.json | jq -r '.messages[].ts' | sort -n | head -n 1)
            has_more=$(cat messages/$team_name/$t/$i/$newest.json | jq -r .has_more)
            if [[ ! -f messages/$team_name/$t/$i/$oldest.json ]]; then
              break
            fi
            if [[ "X$has_more" == "Xfalse" ]]; then
              break
            fi
            newest=$oldest
          done
          if [[ "X$has_more" == "Xfalse" ]]; then
            break
          fi
          if [[ ! -f messages/$team_name/$t/$i/$oldest.json ]]; then
            has_more=$(cat messages/$team_name/$t/$i/$newest.json | jq -r .has_more)
            latest=$(cat messages/$team_name/$t/$i/$newest.json | jq -r '.messages[].ts' | sort -n | head -n 1)
            output=$latest
          fi
        fi
      fi
      sleep 0.001
    fi
  done
  echo "$t - $i : job done!"
done

