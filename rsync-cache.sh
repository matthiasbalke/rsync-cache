#!/bin/sh

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
PROGRESS="--stats --human-readable"

ACTION=cache

show_help() {
    echo usage: rsync-cache.sh -?
}

while getopts "va:k:s:t:h:p:u:?" opt; do
    case "$opt" in
    \?)
        show_help
        exit 0
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
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "ACTION=$ACTION, \nCACHE_KEY=$CACHE_KEY, \nSOURCE_DIR=$SOURCE_DIR, \nTARGET_DIR=$TARGET_DIR, \nTARGET_HOST=$TARGET_HOST, \nTARGET_SSH_PORT=$TARGET_SSH_PORT, \nTARGET_USER=$TARGET_USER, \nLeftovers: $@"

case "$ACTION" in
cache)
    rsync --numeric-ids $PROGRESS -az$VERBOSE -e "ssh -p $TARGET_SSH_PORT" $SOURCE_DIR/ $TARGET_USER@$TARGET_HOST:$TARGET_DIR/$CACHE_KEY
    echo "Cache '$CACHE_KEY' has been created/updated to '$TARGET_DIR/$CACHE_KEY'."
    ;;
restore)
    ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST "[[ -d "$TARGET_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        # ignore empty cache directory
        exit 0
    else
        rsync --numeric-ids $PROGRESS -az$VERBOSE -e "ssh -p $TARGET_SSH_PORT" $TARGET_USER@$TARGET_HOST:$TARGET_DIR/$CACHE_KEY/ $SOURCE_DIR
        echo "Cache '$CACHE_KEY' has been restored to '$SOURCE_DIR'."
    fi
    ;;
clear)
    ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST "[[ -d "$TARGET_DIR/$CACHE_KEY" ]] || exit 42"
    if [ $? == 42 ]
    then
        echo "Cache '$CACHE_KEY' does not exist."
        # ignore empty cache directory
        exit 0
    else
        ssh -p $TARGET_SSH_PORT $TARGET_USER@$TARGET_HOST rm -rf $TARGET_DIR/$CACHE_KEY
        echo "Cache '$CACHE_KEY' has been cleared."
    fi
    ;;
esac