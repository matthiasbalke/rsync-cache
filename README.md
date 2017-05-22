# rsync-cache
rsync-cache is a simple cache script based on rsync and ssh.

I needed a simple and fast way to cache some parts of a jenkins pipeline - like resolved gradle dependencies - to speed up jenkins pipelines which do not have access to other cache systems.

# usage

## cache directory
```sh
$ ./rsync-cache.sh \
    -a cache \
    -k gradle-cache \
    -l ~/.gradle \
    -r /cache \
    -h cache-host.example.com \
    -u cache
```

## restoring remote cache
```sh
$ ./rsync-cache.sh \
    -a resotre \
    -k unique-cache-key \
    -l ~/.gradle \
    -r /cache \
    -h cache-host.example.com \
    -u cache
```

## clearing remote cache
```sh
$ ./rsync-cache.sh \
    -a clear \
    -k unique-cache-key \
    -r /cache \
    -h cache-host.example.com \
    -u cache
```

## arguments
| Argument | Default | Possible Values | Description |
| -------- | ------- | --------------- | ----------- |
| -a | cache | cache, restore, clear   | Action to perform |
| -k | - | String  | Unique Cache Key. Used to define storage dir. |
| -l | `pwd` | Local  Path | Directory to Cache or Restore |
| -r | - | Remote Path | Remote Caching Directory |
| -h | - | Hostname | Remote SSH Hostname |
| -u | `$USER` | Username | Remote SSH Username |
| -p | 22 | Port | Remote SSH Port |
| -c | - | SSH Cipher | Define SSH Cipher to use |
| -m | - | SSH MAC | Define SSH MAC to use |
| -s |  | - | Print transfer statistics |
| -v |  | - | Activate verbose mode for rsync |
| h / -? |  | - | Displays usage info |

## using environment variables
As an alternative to arguments settings can be provided as environment variables. When using both, command line arguments supersede environment variables.

| Argument  | Possible Values | Description |
| --------- | --------------- | ----------- |
| RSYNC_CACHE_ACTION | cache, restore, clear   | Action to perform |
| RSYNC_CACHE_CACHE_KEY | String | Unique Cache Key |
| RSYNC_CACHE_LOCAL_DIR | Local  Path | Directory to Cache or Restore |
| RSYNC_CACHE_REMOTE_DIR | Remote Path | Remote Caching Directory |
| RSYNC_CACHE_REMOTE_HOST | Hostname | Remote SSH Hostname |
| RSYNC_CACHE_REMOTE_USER | Username | Remote SSH Username |
| RSYNC_CACHE_REMOTE_SSH_PORT | Port | Remote SSH Port |
| RSYNC_CACHE_REMOTE_CIPHER | | SSH Cipher | Define SSH Cipher to use |
| RSYNC_CACHE_SSH_MAC | | SSH MAC |  Define SSH MAC to use |
| RSYNC_CACHE_VERBOSE |  | setting any value activates verbose mode | Activate verbose mode for rsync |
| RSYNC_CACHE_STATS  |  | setting any value activates stags | Print transfer statistics |

This way multiple actions can be performed, without defining identical arguments twice:

```sh
export RSYNC_CACHE_CACHE_KEY=gradle-cache
export RSYNC_CACHE_LOCAL_DIR=~/.gradle
export RSYNC_CACHE_REMOTE_DIR=/cache 
export RSYNC_CACHE_REMOTE_HOST=cache-host.example.com 
export RSYNC_CACHE_REMOTE_USER=cache

# restore gradle-cache
./rsync-cache.sh -a restore

# resolve new gradle dependencies
./gradlew build

# update gradle-cache
./rsync-cache.sh -a cache
```