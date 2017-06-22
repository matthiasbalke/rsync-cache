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

function assertSuccessfulExit  {
    LAST_EXIT=$?
    if [ "$LAST_EXIT" -ne "0" ]
    then
        echo "Last action was not successfull. Aborting!"
        exit $LAST_EXIT
    fi
    echo "  ++ Success!"
}

# load ssh agent to connect to docker container
eval $(ssh-agent -s)
chmod 400 integration-test-auth
ssh-add integration-test-auth

echo ""
echo "Starting docker sshd server ..."
# start ssh server
DOCKER_ID=$(docker run -d -P \
    -v `pwd`/source:/mnt/source \
    -v `pwd`/cache:/mnt/cache \
    -v `pwd`/cache_restore:/mnt/cache_restore \
    -v `pwd`/remote:/mnt/remote \
    matthiasbalke/rsync-cache-integration-test:latest)
echo "done."


echo ""
# common settings
export RSYNC_CACHE_REMOTE_HOST=localhost
export RSYNC_CACHE_REMOTE_SSH_PORT=$(docker port $DOCKER_ID 22 | cut -d ':' -f 2)
export RSYNC_CACHE_REMOTE_USER=root
export RSYNC_CACHE_REMOTE_SSH_OPTS='-oStrictHostKeyChecking=no -v'
export RSYNC_CACHE_VERBOSE=true
export RSYNC_CACHE_STATS=true
export RSYNC_CACHE_REMOTE_DIR=/mnt

EXIT_CODE=0

# test: restore empty cache
export RSYNC_CACHE_LOCAL_DIR=`pwd`/source

mkdir restore
../rsync-cache.sh -a restore -k restore
assertSuccessfulExit
echo ""
echo "Restoring empty cache"
# restore should be empty
assertEmptyDir
rm -rf restore

mkdir cache
# test: cache source dir
../rsync-cache.sh -a cache -k cache
assertSuccessfulExit
echo ""
echo "Caching source dir"
# cache should be equal to source
diff -r `pwd`/source `pwd`/cache
assertSuccessfulExit

mkdir cache_restore
# test: restore cached source dir
export RSYNC_CACHE_LOCAL_DIR=`pwd`/cache_restore
../rsync-cache.sh -a restore -k cache
assertSuccessfulExit
echo ""
echo "Caching source dir"
# cache should be equal to source
diff -r `pwd`/source `pwd`/cache_restore
assertSuccessfulExit
rm -rf cache
rm -rf cache_restore

export RSYNC_CACHE_LOCAL_DIR=`pwd`/source

echo ""
# stopping ssh server
echo "Shutting down docker sshd server ..."
docker stop $DOCKER_ID > /dev/null
echo "done."

exit $EXIT_CODE
