FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    htop \
    iproute2 \
    net-tools \
    openssh-server \
    procps \
    sudo \
    vim-tiny \
    wget \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd /root/.ssh \
  && chmod 700 /root/.ssh \
  && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

ARG ROOT_PASSWORD=hallo123
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

RUN ssh-keygen -A

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D", "-e"]
