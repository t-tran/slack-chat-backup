#!/bin/bash

source config.sh

x_ts=$(gdate +%s.%3N)
boundary='---------------------------'$(generate-digits 29)

curl -sv "https://$team_name.slack.com/api/client.boot?_x_id=noversion-$x_ts&_x_version_ts=noversion&_x_gantry=true" \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0' \
-H 'Accept: */*' -H 'Accept-Language: en-US,en;q=0.5' \
-H 'Content-Type: multipart/form-data; boundary='$boundary \
-H 'Origin: https://app.slack.com' \
-H "Cookie: $cookie" \
-H 'Cache-Control: max-age=0' \
--data-binary $'--'$boundary$'\r\nContent-Disposition: form-data; name="token"\r\n\r\n'$token$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="only_self_subteams"\r\n\r\n1\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="flannel_api_ver"\r\n\r\n4\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="include_min_version_bump_check"\r\n\r\n1\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="version_ts"\r\n\r\n'$x_version_ts$'\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_reason"\r\n\r\ndeferred-data\r\n--'$boundary$'\r\nContent-Disposition: form-data; name="_x_sonic"\r\n\r\ntrue\r\n--'$boundary$'--\r\n' \
>meta/boot.json 2>log/boot.log

mkdir -p meta/users
mkdir -p log/meta/users
for i in $(cat meta/boot.json | jq .| grep '"U' | tr -d '":,'); do  if [[ "X$i" == "XU"* ]]; then echo $i; fi; done | sort | uniq | grep -v Used > meta/users.txt
for u in $(cat meta/users.txt); do
  echo -n "Loading profile of user '$u' .."
  while [[ true ]]; do
    curl -sv "https://edgeapi.slack.com/cache/T027BCF4R/users/info" \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0' \
    -H 'Accept: */*' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Content-Type: application/json' \
    -H 'Origin: https://app.slack.com' \
    -H 'DNT: 1' \
    -H 'Connection: keep-alive' \
    -H "Cookie: $cookie" \
    --data '{"token":"'$token'","check_interaction":true,"updated_ids":{"'$u'":0}}' \
    >meta/users/$u.json 2>log/meta/users/$u.log

    status_code=$(cat log/meta/users/$u.log | grep "^< HTTP/" | awk '{ print $3 }')
    if [[ $status_code -ne 200 ]]; then
      # try again
      if [[ $status_code -eq 429 ]]; then
        echo -n s
        sleep 3
      else
        echo -n x
      fi
      sleep 1
    else
      echo -n .
      break
    fi
  done
  echo
done
