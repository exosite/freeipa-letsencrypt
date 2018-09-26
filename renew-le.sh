#!/usr/bin/bash
set -o nounset -o errexit

EMAIL="${EMAIL:-admin@example.com}"
DIRMAN_PASSWORD="${DIRMAN_PASSWORD:-xxx}"
if ["$DIRMAN_PASSWORD" == "-xxx"]
then
    echo "need directory admin password" && exit 1
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
service httpd stop

# get a new cert
certbot certonly -n --standalone --email "$EMAIL" -d "$(hostname -f)" --agree-tos

ipa-server-certinstall -w -d "/etc/letsencrypt/live/$(hostname -f)/privkey.pem" "/etc/letsencrypt/live/$(hostname -f)/cert.pem" -p "$DIRMAN_PASSWORD"

systemctl restart httpd.service
systemctl restart dirsrv@*
