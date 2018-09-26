#!/usr/bin/bash
set -o nounset -o errexit

WORKDIR="/root/ipa-le"

if ! [[ -x "$(command -v certbot)" ]]
then
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true
    yum -y install yum-utils || true
    yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional || true
    yum install -y certbot || true
fi


if [ "${TEST:-no}" == "yes" ]
then
curl -O https://letsencrypt.org/certs/fakeleintermediatex1.pem
curl -O https://letsencrypt.org/certs/fakelerootx1.pem
ipa-cacert-manage install "fakelerootx1.pem" -n fakelerootx1 -t C,,
ipa-cacert-manage install "fakeleintermediatex1.pem" -n fakelex1 -t C,,
fi

ipa-cacert-manage install "$WORKDIR/ca/DSTRootCAX3.pem" -n DSTRootCAX3 -t C,,

ipa-cacert-manage install "$WORKDIR/ca/LetsEncryptAuthorityX3.pem" -n letsencryptx3 -t C,,
ipactl restart
ipa-certupdate -v

"$(dirname "$0")/renew-le.sh" "--first-time"
