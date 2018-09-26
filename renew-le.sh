#!/usr/bin/bash
set -o nounset -o errexit

WORKDIR="${WORKDIR:-/root/ipa-le}"
EMAIL="${EMAIL:-admin@example.com}"
cd "$WORKDIR"

### cron
# check that the cert will last at least 2 days from now to prevent too frequent renewal
# comment out this line for the first run
if [ "${1:-renew}" != "--first-time" ]
then
	certutil -d /etc/httpd/alias/ -V -u V -n Server-Cert -b "$(date '+%y%m%d%H%M%S%z' --date='2 days')" && exit 0
fi

# cert renewal is needed if we reached this line

# cleanup
rm -f "$WORKDIR"/*.pem
rm -f "$WORKDIR"/httpd-csr.*

# generate CSR
certutil -R -d /etc/httpd/alias/ -k Server-Cert -f /etc/httpd/alias/pwdfile.txt -s "CN=$(hostname -f)" --extSAN "dns:$(hostname -f)" -o "$WORKDIR/httpd-csr.der"

# httpd process prevents letsencrypt from working, stop it
service httpd stop

# get a new cert
certbot certonly -n --standalone --csr "$WORKDIR/httpd-csr.der" --email "$EMAIL" --agree-tos

ipa-server-certinstall -w -d "$WORKDIR/0000_cert.pem" "$WORKDIR/0000.cert.crt"

systemctl restart httpd.service
systemctl restart dirsrv@*
