###
### BEGIN: configuration
###

# slack related variables
team_name=
team_id=

cookie=
token=

ims_ignored=""
mpims_ignored=""
channels_ignored=""

# local preferences
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0"
MAX_THREADS=5 # number of jobs to run at the same time
SKIP_ARCHIVED_CHANNELS=1 # whether to skip archived channels
SYNC_INCREMENTAL=0 # whether to do a full sync or just incremental one. default: 0

# these don't need to be changed
x_version_ts=$(date +%s)
x_id=$(echo $x_version_ts | md5sum | cut -c -8)

###
### END: configuration
###
