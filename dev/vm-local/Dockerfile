FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH + Docker + tools (simulates a local homelab server)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    htop \
    iproute2 \
    iptables \
    openssh-server \
    procps \
    sudo \
  && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com | sh

# Configure SSH (password + key auth, like a local server)
RUN mkdir -p /var/run/sshd /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys \
  && chmod 600 /root/.ssh/authorized_keys \
  && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Default root password
ARG ROOT_PASSWORD=hallo123
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

ENV VM_LABEL=vm-local

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 2375

ENTRYPOINT ["/entrypoint.sh"]
