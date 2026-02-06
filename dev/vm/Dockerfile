FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  iproute2 \
  iptables \
  openssh-server \
  sudo \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com | sh

RUN mkdir -p /var/run/sshd /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys \
  && chmod 600 /root/.ssh/authorized_keys \
  && sed -i 's/^[#]*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
  && sed -i 's/^[#]*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
  && sed -i 's/^[#]*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config \
  && sed -i 's/^[#]*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 2375

ENTRYPOINT ["/entrypoint.sh"]
