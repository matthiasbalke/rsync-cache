#!/bin/bash

function assertEmptyDir {
    FILE_COUNT=$(ls -1  `pwd`/restore | wc -l)
    #echo "file count: $FILE_COUNT"

    if [ "$FILE_COUNT" -eq "0" ]
    then
        echo "  ++ Success!"
    else
        echo "  -- Fail!"
        EXIT_CODE=1
    fi
}


# start ssh server
DOCKER_ID=$(docker run -d -P \
    -v `pwd`/source:/mnt/source \
    -v `pwd`/cache:/mnt/cache \
    -v `pwd`/cache_restore:/mnt/cache_restore \
    -v `pwd`/remote:/mnt/remote \
    rastasheep/ubuntu-sshd:14.04)

echo "Docker ID: $DOCKER_ID" 

# common settings
export RSYNC_CACHE_REMOTE_HOST=localhost
export RSYNC_CACHE_REMOTE_SSH_PORT=$(docker port $DOCKER_ID 22 | cut -d ':' -f 2)
export RSYNC_CACHE_REMOTE_USER=root
export RSYNC_CACHE_REMOTE_SSH_OPTS='-oStrictHostKeyChecking=no'
export RSYNC_CACHE_VERBOSE=true
export RSYNC_CACHE_STATS=true
export RSYNC_CACHE_REMOTE_DIR=/mnt

echo "SSH Port:  $RSYNC_CACHE_REMOTE_SSH_PORT"
echo ""

EXIT_CODE=0

# test: restore empty cache
export RSYNC_CACHE_LOCAL_DIR=`pwd`/source

../rsync-cache.sh -a restore -k restore

# restore should be empty
echo "Restoring empty cache"
assertEmptyDir

# stopping ssh server
docker stop $DOCKER_ID > /dev/null
docker rm $DOCKER_ID > /dev/null

exit $EXIT_CODE