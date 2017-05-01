FROM zeroc0d3/ubuntu-core:16.04

MAINTAINER ZeroC0D3 Team <zeroc0d3.0912@gmail.com>

# Install ruby dependencies
RUN apt-get update && \
    apt-get install -y wget curl \
    build-essential git git-core \
    zlib1g-dev libssl-dev libreadline-dev libyaml-dev \
    libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
    openssh-server openssh-client && \

    # Cleanup
    apt-get clean && \
    cd /var/lib/apt/lists && rm -fr *Release* *Sources* *Packages* && \
    truncate -s 0 /var/log/*log


# Install Ruby 2.4.1
RUN cd /tmp &&\
  wget -O ruby-2.4.1.tar.gz https://cache.ruby-lang.org/pub/ruby/2.4/ruby-2.4.1.tar.gz &&\
  tar -xzvf ruby-2.4.1.tar.gz &&\
  cd ruby-2.4.1/ &&\
  ./configure &&\
  make &&\
  make install &&\
  cd /tmp &&\
  rm -rf ruby-2.4.1 &&\
  rm -rf ruby-2.4.1.tar.gz

  # Add Ruby binaries to $PATH
ENV PATH /opt/rubies/ruby-2.4.1/bin:$PATH

# Add options to gemrc
RUN echo "gem: --no-document" > ~/.gemrc

# Install bundler
RUN gem install bundler

# Install foreman
RUN gem install foreman

# Install & configure SSH
# Default ssh root password: secret
# ---------
RUN mkdir -p /var/run/sshd
RUN echo 'root:secret' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
# ---------
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# SSH public key
# ---------
RUN mkdir -p /root/.ssh
RUN chmod 700 /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

EXPOSE 22

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
