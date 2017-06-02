#!/bin/bash

# A POSIX variable
# Reset in case getopts has been used previously in the shell.
OPTIND=1

set_verbose() {
    VERBOSE="v"
}

activate_stats() {
    STATS="--stats --human-readable"
}

# Initialize variables with env/default values
ACTION=${RSYNC_CACHE_ACTION:-cache}
CACHE_KEY=$RSYNC_CACHE_CACHE_KEY
LOCAL_DIR=${RSYNC_CACHE_LOCAL_DIR:-`pwd`}
REMOTE_DIR=$RSYNC_CACHE_REMOTE_DIR
REMOTE_HOST=$RSYNC_CACHE_REMOTE_HOST
REMOTE_SSH_PORT=${RSYNC_CACHE_REMOTE_SSH_PORT:-22}
REMOTE_USER=${RSYNC_CACHE_REMOTE_USER:-$USER}
REMOTE_SSH_CIPHER=$RSYNC_CACHE_SSH_CIPHER
REMOTE_SSH_MAC=$RSYNC_CACHE_SSH_MAC

# activate flags by env values
if [ "$RSYNC_CACHE_VERBOSE" ]
then
    set_verbose
fi

if [ "$RSYNC_CACHE_STATS" ]
then
    activate_stats
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

 -c          SSH Cipher

 -m          SSH MAC

 -S          Print transfer statistics

 -?          Displays this usage info
 "
    echo "$USAGE"
    exit 0
}

while getopts "vsa:c:m:k:l:r:H:p:u:h?" opt; do
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
    c) REMOTE_SSH_CIPHER=$OPTARG
        ;;
    m) REMOTE_SSH_MAC=$OPTARG
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

if [ "$REMOTE_SSH_CIPHER" ]
then
    REMOTE_SSH_CIPHERS="-c $REMOTE_SSH_CIPHER"
fi

if [ "$REMOTE_SSH_MAC" ]
then
    REMOTE_SSH_MACS="-m $REMOTE_SSH_MAC"
fi

case "$ACTION" in
cache)
    echo "Creating/Updating cache '$CACHE_KEY'..."

    # T: turn off pseudo-tty to decrease cpu load on destination.
    # c arcfour: use the weakest but fastest SSH encryption. Must specify "Ciphers arcfour" in sshd_config on destination.
    # o Compression=no: Turn off SSH compression.
    # x: turn off X forwarding if it is on by default.
    rsync --numeric-ids $STATS -a$VERBOSE --delete -e "ssh -p $REMOTE_SSH_PORT -T $REMOTE_SSH_CIPHERS $REMOTE_SSH_MACS -o Compression=no -x" $LOCAL_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$CACHE_KEY
    echo "Done."
    ;;
restore)
    echo "Restoring cache '$CACHE_KEY' to '$LOCAL_DIR' ..."
    if ! ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "test -d \"$REMOTE_DIR/$CACHE_KEY\"";
    then
        echo "Cache '$CACHE_KEY' does not exist."
        echo "Done."
        # ignore empty cache directory
        exit 0
    else

        # T: turn off pseudo-tty to decrease cpu load on destination.
        # c arcfour: use the weakest but fastest SSH encryption. Must specify "Ciphers arcfour" in sshd_config on destination.
        # o Compression=no: Turn off SSH compression.
        # x: turn off X forwarding if it is on by default.
        rsync --numeric-ids $STATS -a$VERBOSE -e "ssh -p $REMOTE_SSH_PORT -T $REMOTE_SSH_CIPHERS $REMOTE_SSH_MACS -o Compression=no -x" $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/$CACHE_KEY/ $LOCAL_DIR
        echo "Done."
    fi
    ;;
clear)
    echo "Clearing cache '$CACHE_KEY' ..."
    if ! ssh -p $REMOTE_SSH_PORT $REMOTE_USER@$REMOTE_HOST "test -d \"$REMOTE_DIR/$CACHE_KEY\""; 
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