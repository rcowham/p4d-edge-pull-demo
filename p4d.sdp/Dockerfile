FROM geerlingguy/docker-centos7-ansible:latest as sdpbase
MAINTAINER Robert Cowham "rcowham@perforce.com"

RUN yum update -y; \
    yum install -y rsync; \
    yum install -y sudo; \
    yum install -y wget; \
    echo /usr/local/lib>> /etc/ld.so.conf; \
    echo /usr/lib64>> /etc/ld.so.conf; \
    sed -ie "s/^Defaults[ \t]*requiretty/#Defaults  requiretty/g" /etc/sudoers

RUN yum install -y openssh-server openssh-clients passwd; \
    yum clean all; \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''; \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''

# Python 3.6 plus p4python
RUN yum install -y https://repo.ius.io/ius-release-el7.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
    yum update; \
    yum install -y python36u python36u-libs python36u-devel python36u-pip; \
    ln -f -s /usr/bin/python3.6 /usr/bin/python3; \
    ln -f -s /usr/bin/pip3.6 /usr/bin/pip3;

RUN pip3.6 install p4python==2017.2.1615960

ADD setup_container.sh /tmp
RUN /bin/bash -x /tmp/setup_container.sh

ADD insecure_ssh_key.pub /tmp
ADD insecure_ssh_key /tmp
ADD setup_ssh.sh /tmp

RUN /bin/bash -x /tmp/setup_ssh.sh

# Replace systemctl for use within docker
RUN cd /usr/local/bin; \
  wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py; \
  chmod 755 systemctl3.py; \
  cd /usr/local/bin; \
  mv systemctl systemctl.old; \
  ln -s /usr/local/bin/systemctl3.py systemctl; \
  cd /usr/bin; \
  mv systemctl systemctl.old; \
  ln -s /usr/local/bin/systemctl3.py systemctl

# For SSH
EXPOSE 22


# ==================================================================
# Dockerfile for master target - builds on the above
# Installs SDP

FROM sdpbase as sdpmaster

USER root

RUN mkdir -p /hxdepots/reset; \
    cd /hxdepots/reset; \
    curl -k -s -O https://swarm.workshop.perforce.com/view/guest/perforce_software/helix-installer/ami-builder/src/ami_install_sdp.sh; \
    chmod +x ami_install_sdp.sh; \
    ./ami_install_sdp.sh -no_cron -sd

# RUN ln -s /p4/common/bin/p4 /usr/local/bin/p4

USER perforce
ADD ansible.cfg /p4
ADD hosts /p4
ADD install_sdp.yml /p4
ADD replica_tasks.yml /p4
ADD configure_master.sh /p4
ADD configure_edge.sh /p4
ADD pull_test.sh /p4
ADD submit_test.sh /p4

USER root
