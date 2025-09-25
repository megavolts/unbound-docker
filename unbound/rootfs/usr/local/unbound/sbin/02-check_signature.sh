#/bin/bash!
GNUPGHOME="$(mktemp -d)" &&
export GNUPGHOME &&
gpg --no-tty --recv-keys F0CB1A326BDF3F3EFA3A01FA937BB869E3A238C5 &&
gpg --verify /usr/local/unbound/iana.d/root.hints.sig /usr/local/unbound/iana.d/root.hints &&
gpg --verify /usr/local/unbound/iana.d/root.zone.sig /usr/local/unbound/iana.d/root.zone &&
/usr/local/unbound/unbound.d/sbin/unbound-anchor -v -a /usr/local/unbound/iana.d/root.key || true &&
pkill -9 gpg-agent &&
pkill -9 dirmngr &&
rm /usr/local/unbound/iana.d/root.hints.* &&
rm /usr/local/unbound/iana.d/root.zone.*