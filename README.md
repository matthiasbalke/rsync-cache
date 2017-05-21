# rsync-cache
rsync-cache is a simple cache script based on rsync and ssh.

I needed a simple and fast way to cache some parts of a jenkins pipeline - like resolved gradle dependencies - to speed up jenkins pipelines which do not have access to other cache systems.

# usage

## cache directory
```sh
$ ./rsync-cache.sh \
    -a cache \
    -k gradle-cache \
    -s ~/.gradle \
    -t /cache \
    -h cache-host.example.com \
    -u cache
```

## restoring remote cache
```sh
$ ./rsync-cache.sh \
    -a resotre \
    -k unique-cache-key \
    -s ~/.gradle \
    -t /cache \
    -h cache-host.example.com \
    -u cache
```

## clearing remote cache
```sh
$ ./rsync-cache.sh \
    -a clear \
    -k unique-cache-key \
    -t /cache \
    -h cache-host.example.com \
    -u cache
```

## arguments
| Argument | Default | Possible Values | Description |
| -------- | ------- | --------------- | ----------- |
| -a | cache | cache, restore, clear   | Action to perform |
| -k | - | String  | Unique Cache Key. Used to define storage dir. |
| -s | `pwd` | Local  Path | Directory to Cache or Restore |
| -t | - | Remote Path | Remote Caching Directory |
| -h | - | Hostname | Remote SSH Hostname |
| -u | `$USER` | Username | Remote SSH Username |
| -p | 22 | Port | Remote SSH Port |
| -S |  | - | Print transfer statistics |
| -? |  | - | Displays usage info |
