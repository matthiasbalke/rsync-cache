docker rm -f $(docker ps -a | grep rastasheep/ubuntu-sshd:14.04 | cut -d ' ' -f 1)
