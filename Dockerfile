FROM ruby:2.6

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get install -y \
    apt-utils \
    build-essential \
    ntp libyaml-dev libevent-dev zlib1g zlib1g-dev openssl libssl-dev libxml2 \
    ruby redis \
  && rm -rf /var/lib/apt/lists/*

# Download OTS from github
RUN set -ex && \
  mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
  mkdir /gittmp && \
  cd /gittmp && \
  git clone https://github.com/croixbleueqc/onetimesecret.git && \
  cp -rp /gittmp/onetimesecret/* /var/lib/onetime/


# Install OTS
RUN cd /var/lib/onetime && \
  bundle install && \
  cp -R etc/* /etc/onetime/

# Add config and entrypoint
ADD config.example /etc/onetime/config
ADD entrypoint.sh /usr/bin/

VOLUME /etc/onetime /var/run/redis

EXPOSE 7143/tcp

# RUN ["chmod", "+x", "/usr/bin/entrypoint.sh"]
ENTRYPOINT /usr/bin/entrypoint.sh