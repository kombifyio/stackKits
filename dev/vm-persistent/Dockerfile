FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH + Docker + essential tools
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

# Configure SSH (password + key auth)
RUN mkdir -p /var/run/sshd /root/.ssh \
  && chmod 700 /root/.ssh \
  && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Default root password (override with ROOT_PASSWORD env var at build time)
ARG ROOT_PASSWORD=hallo123
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 2375

ENTRYPOINT ["/entrypoint.sh"]
