FROM alpine:3.5

LABEL maintainer "matthias.balke@googlemail.com"

# check which package provides which command
# https://pkgs.alpinelinux.org/contents
RUN apk --no-cache add \
    "openssh=7.4_p1-r0" \
    "bash=4.3.46-r5" \
    "curl=7.52.1-r3" \
    "ca-certificates=20161130-r1" \
    "openssl=1.0.2k-r0" \
    "shadow=4.2.1-r8" \
    "rsync=3.1.2-r2"

# make bash the default shell
RUN chsh -s /bin/bash

# root should be able to login
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

# generate SSHd server keys
RUN /usr/bin/ssh-keygen -A

# add rsync-cache.sh
ADD rsync-cache.sh /usr/bin/rsync-cache.sh

# create non root user
RUN useradd --create-home --shell /bin/bash --user-group cache

USER cache

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
