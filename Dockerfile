FROM ubuntu:24.04

# Base packages for the outer CTF host: its own Docker engine plus sshd.
RUN apt-get update \
    && apt-get install -y docker.io docker-compose-v2 openssh-server nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Setup docker env + ssh env" \
    && mkdir -p /var/lib/docker /run/sshd \
    && sed -i "s/#PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config \
    && sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config \
    && ssh-keygen -A \
    && echo "Adding deploy account netops" \
    && useradd -m netops \
    && echo -n "netops:IyMBegU3KYWFwymcHybD2Tun" | chpasswd \
    && userdel ubuntu \
    && echo "Bash configuring" \
    && sed -i 's#/bin/sh#/bin/bash#' /etc/passwd \
    && echo "Linking .bash_history to /dev/null" \
    && ln -sf /dev/null /root/.bash_history \
    && ln -sf /dev/null /home/netops/.bash_history

# Copying flags + inner stack build context
COPY ./main_flags/root.txt /root/root.txt
COPY ./main_flags/user.txt /home/netops/user.txt
COPY ./docker-web /root/docker-web

RUN echo "Permissions for flags" \
    && chown root:root /root/root.txt && chmod 0400 /root/root.txt \
    && chown netops:netops /home/netops/user.txt && chmod 0400 /home/netops/user.txt \
    && echo "Keep the inner build context out of reach of the deploy account" \
    && chmod 0700 /root/docker-web

# Store the inner Docker engine's data on a volume so the nested engine does not
# run overlay-on-overlay (matches the official docker:dind image). Without this,
# inner image builds fail on hosts whose /var/lib/docker is itself an overlay
# filesystem (for example Docker Desktop).
VOLUME /var/lib/docker

EXPOSE 22 23 8080

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD ["docker", "compose", "-f", "/root/docker-web/docker-compose.yaml", "up"]
