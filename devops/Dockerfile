FROM ruby:2.3

# Install dependencies for ruby 2.3
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get install -y \
    build-essential \
    redis-server \
  && rm -rf /var/lib/apt/lists/*

# Get code from local
RUN mkdir /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
  mkdir /gittmp
COPY . /gittmp/onetimesecret
RUN cd /gittmp && \
  cp -rp /gittmp/onetimesecret/* /var/lib/onetime/ && \
  rm -r /gittmp

# Clone directory OTS from github
# RUN set -ex && \
#   mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
#   mkdir /gittmp && \
#   cd /gittmp && \
#   git clone https://github.com/croixbleueqc/onetimesecret.git && \
#   cp -rp /gittmp/onetimesecret/* /var/lib/onetime/ && \
#   rm -r /gittmp

# Download OTS from github release tag
# RUN set -ex && \
#   mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
#   wget https://github.com/croixbleueqc/onetimesecret/archive/refs/tags/v0.12.2.tar.gz -O /tmp/ots.tar.gz && \
#   tar xzf /tmp/ots.tar.gz -C /var/lib/onetime --strip-components=1 && \
#   rm /tmp/ots.tar.gz

# Install OTS
RUN cd /var/lib/onetime && \
  bundle install && \
  cp -R etc/* /etc/onetime/

# Copy config and entrypoint
RUN cp /var/lib/onetime/devops/config.example /etc/onetime/config
RUN cp /var/lib/onetime/devops/entrypoint.sh /usr/bin/

VOLUME /etc/onetime /var/run/redis

ENV RACK_ENV=prod

EXPOSE 7143/tcp

RUN ["chmod", "+x", "/usr/bin/entrypoint.sh"]
ENTRYPOINT /usr/bin/entrypoint.sh