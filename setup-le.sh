#!/usr/bin/bash
set -o nounset -o errexit

WORKDIR="/root/ipa-le"

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true
yum -y install yum-utils || true
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional || true
yum install -y certbot || true


ipa-cacert-manage install "$WORKDIR/ca/DSTRootCAX3.pem" -n DSTRootCAX3 -t C,,
ipa-certupdate -v

ipa-cacert-manage install "$WORKDIR/ca/LetsEncryptAuthorityX3.pem" -n letsencryptx3 -t C,,
ipa-certupdate -v

"$(dirname "$0")/renew-le.sh" "--first-time"
