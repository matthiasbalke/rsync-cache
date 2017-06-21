docker rm -f $(docker ps -a | grep matthiasbalke/rsync-cache-integration-test:latest | cut -d ' ' -f 1)
