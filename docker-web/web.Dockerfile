FROM php:8.4-apache

ARG DOCKER_CLI_VERSION=29.8.0

# Diagnostic binaries plus the tooling the challenge needs: sudo for the
# privilege step, openssh-server for the inner SSH pivot, gawk for the sudo
# GTFOBins step, and curl/ca-certificates to fetch the static Docker client.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo openssh-server gawk \
        iputils-ping dnsutils whois \
        curl ca-certificates && \
    echo "Installing a static Docker CLI (used for the final socket breakout)" \
    && arch="$(uname -m)" \
    && curl -fsSL "https://download.docker.com/linux/static/stable/${arch}/docker-${DOCKER_CLI_VERSION}.tgz" -o /tmp/docker.tgz \
    && tar -xzf /tmp/docker.tgz -C /usr/local/bin --strip-components=1 docker/docker \
    && rm -f /tmp/docker.tgz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Serve the console on 8080 so the outer container can publish it there.
RUN sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf && \
    sed -i 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf

# Diagnostics operator account reached over the inner SSH pivot. The password
# is meant to be recovered (read from the app config), not cracked, so it is
# high entropy.
RUN useradd -m -s /bin/bash diag && \
    echo 'diag:msCUXbubEdnMpXFL74CyD3uK' | chpasswd && \
    mkdir -p /run/sshd && \
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    ln -sf /dev/null /root/.bash_history && \
    ln -sf /dev/null /home/diag/.bash_history

# Application config that leaks the operator credential to anyone who can read
# it as www-data (the OS command injection lands there).
COPY --chown=root:root --chmod=644 ./config/scheduler.conf /opt/netdiag/scheduler.conf
RUN chmod 0755 /opt/netdiag

# Deployment notes that leak the outer host account, readable only once you are
# root inside this container.
COPY --chown=root:root --chmod=400 ./config/deploy-notes.txt /root/deploy-notes.txt

# Flags
COPY --chown=www-data:www-data --chmod=400 ./flags/web.txt /var/www/user_flag.txt
COPY --chown=diag:diag --chmod=400 ./flags/diag.txt /home/diag/diag.txt
COPY --chown=root:root --chmod=400 ./flags/root.txt /root/root.txt

COPY --chown=root:root --chmod=440 ./sudoers /etc/sudoers

COPY --chmod=644 ./html/ /var/www/html/

EXPOSE 8080 22

CMD service ssh start && apache2-foreground
