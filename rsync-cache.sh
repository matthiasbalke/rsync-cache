#!/bin/bash

# A POSIX variable
# Reset in case getopts has been used previously in the shell.
OPTIND=1

# Initialize variables with default values
CACHE_KEY=

SOURCE_DIR=`pwd`
TARGET_DIR=
TARGET_HOST=
TARGET_SSH_PORT=22
TARGET_USER=$USER
VERBOSE=
STATS=

ACTION=cache

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

while getopts "va:k:s:t:h:p:u:?" opt; do
    case "$opt" in
    \?)
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
    s) SOURCE_DIR=$OPTARG
        ;;
    t) TARGET_DIR=$OPTARG
        ;;
    h) TARGET_HOST=$OPTARG
        ;;
    p) TARGET_SSH_PORT=$OPTARG
        ;;
    u) TARGET_USER=$OPTARG
        ;;
    v) VERBOSE=v
        ;;
    S) STATS="--stats --human-readable"
        ;;
    *) show_help
       ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

# check for mandatory arguments
if [ ! "$CACHE_KEY" ] || [ ! "$SOURCE_DIR" ] || [ ! "$TARGET_DIR" ] || [ ! "$TARGET_HOST" ] || [ ! "$TARGET_SSH_PORT" ] || [ ! "$TARGET_USER" ]
then
    show_help
fi

case "$ACTION" in
cache)
    echo "Creating/Updating cache '$CACHE_KEY'..."
    rsync --numeric-ids $STATS -az$VERBOSE -e "ssh -p $TARGET_SSH_PORT" $SOURCE_DIR/ $TARGET_USER@$TARGET_HOST:$TARGET_DIR/$CACHE_KEY
    echo "Done."
    ;;
restore)
    echo "Restoring cache '$CACHE_KEY' to '$SOURCE_DIR' ..."
    ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST "[[ -d "$TARGET_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        echo "Done."
        # ignore empty cache directory
        exit 0
    else
        rsync --numeric-ids $STATS -az$VERBOSE -e "ssh -p $TARGET_SSH_PORT" $TARGET_USER@$TARGET_HOST:$TARGET_DIR/$CACHE_KEY/ $SOURCE_DIR
        echo "Done."
    fi
    ;;
clear)
    echo "Clearing cache '$CACHE_KEY' ..."
    ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST "[[ -d "$TARGET_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        echo "Done."
        # ignore empty cache directory
        exit 0
    else
        ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST rm -rf $TARGET_DIR/$CACHE_KEY
        echo "Done."
    fi
    ;;
esac