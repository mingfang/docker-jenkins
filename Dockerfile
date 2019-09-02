FROM ubuntu:18.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/bin/runsvdir /etc/service'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute2 python ssh rsync gettext-base

# Java
RUN apt-get -y install openjdk-8-jdk

#Subversion
RUN apt-get install -y subversion

#Docker client only
RUN wget -O - https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar zx -C /usr/local/bin --strip-components=1 docker/docker

#Kubectl
RUN cd /usr/bin && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.11.1/bin/linux/amd64/kubectl && \
    chmod +x kubectl

#Jenkins
RUN wget http://updates.jenkins-ci.org/download/war/2.193/jenkins.war

#Install plugins
RUN curl -L https://raw.githubusercontent.com/hgomez/devops-incubator/master/forge-tricks/batch-install-jenkins-plugins.sh -o batch-install-jenkins-plugins.sh && \
    chmod +x batch-install-jenkins-plugins.sh

COPY plugins.txt /
RUN mkdir -p /jenkins/plugins && \
    ./batch-install-jenkins-plugins.sh --plugins plugins.txt --plugindir /jenkins/plugins

#Trust Github, this is needed for SCM Configuration Plugin
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
