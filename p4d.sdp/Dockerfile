FROM centos:centos7 as sdpbase
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
RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm; \
    yum update; \
    yum install -y python36u python36u-libs python36u-devel python36u-pip; \
    ln -s /usr/bin/python3.6 /usr/bin/python3; \
    ln -s /usr/bin/pip3.6 /usr/bin/pip3;

RUN pip3.6 install p4python==2017.2.1615960 testinfra ansible

ADD setup_container.sh /tmp
RUN /bin/bash -x /tmp/setup_container.sh

ADD insecure_ssh_key.pub /tmp
ADD insecure_ssh_key /tmp
ADD setup_ssh.sh /tmp

RUN /bin/bash -x /tmp/setup_ssh.sh

# For SSH
EXPOSE 22


# ==================================================================
# Dockerfile for master target - builds on the above
# Installs SDP

FROM sdpbase as sdpmaster

USER root
RUN pip3.6 install ansible 

RUN mkdir -p /hxdepots/reset && \
    cd /hxdepots/reset && \
    curl -k -s -O https://swarm.workshop.perforce.com/download/guest/perforce_software/helix-installer/main/src/reset_sdp.sh && \
    chmod +x reset_sdp.sh && \
    ./reset_sdp.sh -fast -no_ssl

RUN ln -s /p4/common/bin/p4 /usr/local/bin/p4

USER perforce
ADD ansible.cfg /p4
ADD hosts /p4
ADD install_sdp.yml /p4
ADD replica_tasks.yml /p4
ADD docker_entry_master.sh /p4

USER root