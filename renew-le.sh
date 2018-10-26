#!/usr/bin/bash
set -o nounset -o errexit

if [ -z "$DIRMAN_PASSWORD" ]
then
    echo "need directory admin password" && exit 1
fi
if [ -z "$EMAIL" ]
then
    echo "need admin email" && exit 1
fi


EXTRA_CERTBOT_ARG="${EXTRA_CERTBOT_ARG:-}"
if [ "${TEST:-no}" == "yes" ]
then
    EXTRA_CERTBOT_ARG="${EXTRA_CERTBOT_ARG} --test-cert"
fi

### cron
# check that the cert will last at least 2 days from now to prevent too frequent renewal
# comment out this line for the first run
if [ "${1:-renew}" != "--first-time" ]
then
	certutil -d /etc/httpd/alias/ -V -u V -n Server-Cert -b "$(date '+%y%m%d%H%M%S%z' --date='2 days')" && exit 0
fi

# cert renewal is needed if we reached this line

# httpd process prevents letsencrypt from working, stop it
systemctl stop httpd

# get a new cert
# shellcheck disable=SC2086
certbot certonly -n --standalone ${EXTRA_CERTBOT_ARG} --email "$EMAIL" -d "$(hostname -f)" --agree-tos

ipa-server-certinstall -w -d "/etc/letsencrypt/live/$(hostname -f)/privkey.pem" "/etc/letsencrypt/live/$(hostname -f)/cert.pem" -p "$DIRMAN_PASSWORD" --pin=

ipactl restart
