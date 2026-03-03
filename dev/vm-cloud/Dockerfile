FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH + Docker + tools (simulates a cloud VPS)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    htop \
    iproute2 \
    iptables \
    jq \
    netcat-openbsd \
    openssh-server \
    procps \
    sudo \
  && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN curl -fsSL https://get.docker.com | sh

# Configure SSH (key-only by default, like a real cloud VM)
RUN mkdir -p /var/run/sshd /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys \
  && chmod 600 /root/.ssh/authorized_keys \
  && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Cloud VM metadata
ENV CLOUD_PROVIDER_SIM=azure
ENV CLOUD_REGION_SIM=westeurope
ENV CLOUD_INSTANCE_TYPE=Standard_B2s
ENV VM_LABEL=vm-cloud

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 2375 8169

ENTRYPOINT ["/entrypoint.sh"]
