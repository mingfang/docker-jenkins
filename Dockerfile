FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    TERM=xterm
RUN locale-gen en_US en_US.UTF-8
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /root/.bashrc
RUN echo "export PS1='\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" >> /etc/bash.bashrc
RUN apt-get update

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD export > /etc/envvars && /usr/sbin/runsvdir-start
RUN echo 'export > /etc/envvars' >> /root/.bashrc

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh

#Install Oracle Java 8
RUN add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java8-installer && \
    apt install oracle-java8-unlimited-jce-policy && \
    rm -r /var/cache/oracle-jdk8-installer
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

#Subversion
RUN apt-get install -y subversion

#Docker client only
RUN wget -O - https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar zx -C /usr/local/bin --strip-components=1 docker/docker

#Kubectl
RUN cd /usr/bin && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.4.6/bin/linux/amd64/kubectl && \
    chmod +x kubectl

#Ansible
RUN apt-get install -y libssl-dev libffi-dev python-dev python-pip
RUN pip install --upgrade setuptools
RUN pip install httplib2
RUN pip install ansible

#Sonar Runner
RUN wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-2.6.1.zip && \
    unzip sonar*zip && \
    ln -s /sonar-scanner-*/bin/sonar-scanner /usr/local/bin && \
    rm sonar*zip

#Jenkins
RUN wget http://updates.jenkins-ci.org/download/war/2.34/jenkins.war

#Install plugins
RUN curl -L https://raw.githubusercontent.com/hgomez/devops-incubator/master/forge-tricks/batch-install-jenkins-plugins.sh -o batch-install-jenkins-plugins.sh && \
    chmod +x batch-install-jenkins-plugins.sh

COPY plugins.txt /
RUN mkdir -p /root/.jenkins/plugins && \
    ./batch-install-jenkins-plugins.sh --plugins plugins.txt --plugindir /root/.jenkins/plugins

#Trust Github, this is needed for SCM Configuration Plugin
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts

COPY config.xml /root/.jenkins/

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO
