#/bin/bash!
# Download root.zone
curl -sSL https://www.internic.net/domain/root.zone -o /usr/local/unbound/iana.d/root.zone &&
curl -sSL https://www.internic.net/domain/root.zone.md5 -o /usr/local/unbound/iana.d/root.zone.md5 &&
curl -sSL https://www.internic.net/domain/root.zone.sig -o /usr/local/unbound/iana.d/root.zone.sig &&
ROOT_ZONE_MD5=`cat /usr/local/unbound/iana.d/root.zone.md5` &&
echo "${ROOT_ZONE_MD5} */usr/local/unbound/iana.d/root.zone" | md5sum -c -
