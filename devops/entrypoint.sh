#!/bin/bash

# NOTE: sed -i doesn't work when configs are mount points

# set OTS secret if supplied by ENV or if default
if [[ -n ${OTS_SECRET+x} ]]; then
  echo "Setting OTS secret to $OTS_SECRET"
  cp /etc/onetime/config{,.bak}
  sed "s/:secret:.*\$/:secret: $OTS_SECRET/" /etc/onetime/config.bak > /etc/onetime/config
elif grep -q ":secret: CHANGEME" /etc/onetime/config; then
  PASS="$(dd if=/dev/urandom bs=20 count=1 2>/dev/null| openssl sha1 | grep -o '[a-f0-9]\{40\}')"
  echo "Generating random OTS secret"
  cp /etc/onetime/config{,.bak}
  sed "s/:secret:.*\$/:secret: $PASS/" /etc/onetime/config.bak > /etc/onetime/config
fi

# remove redis password and change to default port
if grep -q "redis://user:CHANGEME@127.0.0.1:7179" /etc/onetime/config; then
  cp /etc/onetime/config{,.bak}
  sed "s/redis:\/\/user:CHANGEME@127\.0\.0\.1:7179/redis:\/\/127\.0\.0\.1:6379/" /etc/onetime/config.bak > /etc/onetime/config
fi

# change default sender name in automated emails
# (even better, create and mount your own email templates at the locations below)
if [[ -n ${OTS_NAME+x} ]]; then
  echo "Setting email sender name to $OTS_NAME"
  sed -i.bak "s/Admin/$OTS_NAME/" /var/lib/onetime/templates/email/password_request.mustache
  sed -i.bak "s/Admin/$OTS_NAME/" /var/lib/onetime/templates/email/welcome.mustache
fi

# configure host
if [[ ! -z "$OTS_HOST" ]]; then
  echo "Setting config host to $OTS_HOST"
  cp /etc/onetime/config{,.bak}
  sed "s/:host:.*\$/:host: $OTS_HOST/" /etc/onetime/config.bak > /etc/onetime/config
  cp /etc/onetime/config{,.bak}
  sed "s/:domain:.*\$/:domain: $OTS_HOST/" /etc/onetime/config.bak > /etc/onetime/config
fi

# start Redis
/etc/init.d/redis-server start

# start OTS
cd /var/lib/onetime && bundle exec thin -e prod -R config.ru -p 7143 start