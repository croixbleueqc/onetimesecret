FROM ruby:2.3

# Install dependencies for ruby 2.3
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get install -y \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# Get code from local
# RUN mkdir /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
#   mkdir /gittmp
# COPY . /gittmp/onetimesecret
# RUN cd /gittmp && \
#   cp -rp /gittmp/onetimesecret/* /var/lib/onetime/ && \
#   rm -r /gittmp

# Clone directory OTS from github
# RUN set -ex && \
#   mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
#   mkdir /gittmp && \
#   cd /gittmp && \
#   git clone https://github.com/croixbleueqc/onetimesecret.git && \
#   cp -rp /gittmp/onetimesecret/* /var/lib/onetime/ && \
#   rm -r /gittmp

# Download OTS from github release tag
RUN set -ex && \
  mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime && \
  wget https://github.com/croixbleueqc/onetimesecret/archive/refs/tags/v0.12.3.tar.gz -O /tmp/ots.tar.gz && \
  tar xzf /tmp/ots.tar.gz -C /var/lib/onetime --strip-components=1 && \
  rm /tmp/ots.tar.gz

# Install OTS
RUN cd /var/lib/onetime && \
  bundle install && \
  cp -R etc/* /etc/onetime/

RUN rm /etc/onetime/config && ln -s /mnt/config/ots.config /etc/onetime/config

ENV RACK_ENV=prod

EXPOSE 7143/tcp

WORKDIR /var/lib/onetime
# bundle exec thin -e prod -R config.ru -p 7143 start
ENTRYPOINT ["bundle", "exec", "thin", "-e", "prod", "-R", "config.ru", "-p", "7143", "start"]