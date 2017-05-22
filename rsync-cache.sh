#!/bin/bash

# A POSIX variable
# Reset in case getopts has been used previously in the shell.
OPTIND=1

set_verbose() {
    VERBOSE=v
}

activate_stats() {
    STATS="--stats --human-readable"
}

# Initialize variables with env values
ACTION=$RSYNC_CACHE_ACTION
CACHE_KEY=$RSYNC_CACHE_CACHE_KEY
LOCAL_DIR=$RSYNC_CACHE_LOCAL_DIR
REMOTE_DIR=$RSYNC_CACHE_REMOTE_DIR
REMOTE_HOST=$RSYNC_CACHE_REMOTE_HOST
REMOTE_SSH_PORT=$RSYNC_CACHE_REMOTE_SSH_PORT
REMOTE_USER=$RSYNC_CACHE_REMOTE_USER

# activate flags by env values
if [ "$RSYNC_CACHE_VERBOSE" ]
then
    set_verbose
fi

if [ "$RSYNC_CACHE_STATS" ]
then
    activate_stats
fi

# Initialize variables with default values if not already set
if [ ! "$ACTION" ]
then
    ACTION=cache
fi

if [ ! "$LOCAL_DIR" ]
then
    LOCAL_DIR=`pwd`
fi

if [ ! "$REMOTE_SSH_PORT" ]
then
    REMOTE_SSH_PORT=22
fi

if [ ! "$REMOTE_USER" ]
then
    REMOTE_USER=$USER
fi

# check that needed binaries are installed
hash rsync 2>/dev/null  || { echo "rsync-cache relies on rsync beeing installed. Please install it before using rsync-cache. Aborting.";  exit 2; }
hash ssh 2>/dev/null    || { echo "rsync-cache relies on ssh beeing installed. Please install it before using rsync-cache. Aborting.";  exit 2; }

show_help() {

    USAGE="
 usage: rsync-cache.sh [OPTIONS]

 Options
 -a          Action to perform:
             [cache, restore, clear]
             default: cache

 -k          Unique Cache Key. Used to define storage dir.

 -s          Directory to Cache or Restore
             default: pwd

 -t          Remote Caching Directory

 -h          Remote SSH Hostname

 -u          Remote SSH Username
             default: $USER

 -p          Remote SSH Port
             default: 22

 -S          Print transfer statistics

 -?          Displays this usage info
 "
    echo "$USAGE"
    exit 0
}

while getopts "vsa:k:l:r:H:p:u:h?" opt; do
    case "$opt" in
    h | \?)
        show_help
        ;;
    a)
        case "$OPTARG" in
            cache | restore | clear)
                ACTION=$OPTARG
                ;;
            *)  show_help
                exit 1;
                ;;
        esac
        ;;
    k) CACHE_KEY=$OPTARG
        ;;
    l) LOCAL_DIR=$OPTARG
        ;;
    r) REMOTE_DIR=$OPTARG
        ;;
    H) REMOTE_HOST=$OPTARG
        ;;
    p) REMOTE_SSH_PORT=$OPTARG
        ;;
    u) REMOTE_USER=$OPTARG
        ;;
    v) set_verbose
        ;;
    s) activate_stats
        ;;
    *) show_help
       ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# check for mandatory arguments
if [ ! "$CACHE_KEY" ] || [ ! "$LOCAL_DIR" ] || [ ! "$REMOTE_DIR" ] || [ ! "$REMOTE_HOST" ] || [ ! "$REMOTE_SSH_PORT" ] || [ ! "$REMOTE_USER" ]
then
    show_help
fi

case "$ACTION" in
cache)
    echo "Creating/Updating cache '$CACHE_KEY'..."
    rsync --numeric-ids $STATS -az$VERBOSE -e "ssh -p $REMOTE_SSH_PORT" $LOCAL_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$CACHE_KEY
    echo "Done."
    ;;
restore)
    echo "Restoring cache '$CACHE_KEY' to '$LOCAL_DIR' ..."
    ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "[[ -d "$REMOTE_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        echo "Done."
        # ignore empty cache directory
        exit 0
    else
        rsync --numeric-ids $STATS -az$VERBOSE -e "ssh -p $REMOTE_SSH_PORT" $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$CACHE_KEY/ $LOCAL_DIR
        echo "Done."
    fi
    ;;
clear)
    echo "Clearing cache '$CACHE_KEY' ..."
    ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "[[ -d "$REMOTE_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        echo "Done."
        # ignore empty cache directory
        exit 0
    else
        ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST rm -rf $REMOTE_DIR/$CACHE_KEY
        echo "Done."
    fi
    ;;
esac