FROM rastasheep/ubuntu-sshd:14.04

RUN apt-get update && apt-get install -y rsync && rm -rf /var/lib/apt/lists/*

RUN mkdir /root/.ssh
ADD integration-test-auth.pub /root/.ssh/authorized_keys
RUN chmod 700 /root/.ssh
RUN chmod 600 /root/.ssh/authorized_keys