FROM ubuntu:14.04
MAINTAINER Olivier Louvignes <olivier@mg-crea.com>
# @cli docker build -t mgcrea/supervisord-build .

# Setup environment
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install base packages
RUN echo 'APT::Install-Recommends 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && echo 'APT::Install-Suggests 0;' >> /etc/apt/apt.conf.d/01norecommends \
 && apt-get update \
 && apt-get install -y vim.tiny wget sudo net-tools ca-certificates unzip \
 && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install SSH
RUN apt-get update && apt-get install -y openssh-server
# SSH startup fix. Missing privilege separation directory: /var/run/sshd
RUN mkdir /var/run/sshd
# SSH login fix. Otherwise user is kicked off after login
# @url http://docs.docker.com/v1.6/examples/running_ssh_service/
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
EXPOSE 22

# Add .bash_aliases on build
ONBUILD ADD files/.bash_aliases /root/.bash_aliases
# Add authorized SSH key on build
ONBUILD ADD files/authorized_keys /tmp/authorized_keys
ONBUILD RUN mkdir /root/.ssh; cat /tmp/authorized_keys > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys; rm -f /tmp/authorized_keys
# Regenerate host SSH keys on build
ONBUILD RUN dpkg-reconfigure openssh-server

# Install Supervisord
RUN apt-get install -y supervisor
ADD files/supervisord.conf /etc/supervisor/supervisord.conf

# Run Supervisord
CMD ["/usr/bin/supervisord"]
