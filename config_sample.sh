# shellcheck shell=bash

###
### BEGIN: configuration
###

# slack related variables
export team_name
team_name=
export team_id
team_id=

export cookie
cookie=
export token
token=

export ims_ignored
ims_ignored=""
export mpims_ignored
mpims_ignored=""
export channels_ignored
channels_ignored=""

# local preferences
export USER_AGENT
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0"
export MAX_THREADS
MAX_THREADS=5 # number of jobs to run at the same time
export SKIP_ARCHIVED_CHANNELS
SKIP_ARCHIVED_CHANNELS=1 # whether to skip archived channels
export SYNC_INCREMENTAL
SYNC_INCREMENTAL=0 # whether to do a full sync or just incremental one. default: 0

# these don't need to be changed
export x_version_ts
x_version_ts=$(date +%s)
export x_id
x_id=$(echo "$x_version_ts" | md5sum | cut -c -8)

###
### END: configuration
###
