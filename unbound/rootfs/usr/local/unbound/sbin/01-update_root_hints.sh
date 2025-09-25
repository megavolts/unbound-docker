#/bin/bash!
# Download root.zone
curl -sSL https://www.internic.net/domain/named.cache -o /usr/local/unbound/iana.d/root.hints &&
curl -sSL https://www.internic.net/domain/named.cache.md5 -o /usr/local/unbound/iana.d/root.hints.md5 &&
curl -sSL https://www.internic.net/domain/named.cache.sig -o /usr/local/unbound/iana.d/root.hints.sig &&
ROOT_HINTS_MD5=`cat /usr/local/unbound/iana.d/root.hints.md5` &&
echo "${ROOT_HINTS_MD5} */usr/local/unbound/iana.d/root.hints" | md5sum -c -
