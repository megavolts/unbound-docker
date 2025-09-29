ARG BUILD_REPOSITORY="megavolts/unbound" \
    BUILD_NAME="Unbound" \
    BUILD_DESCRIPTION="Unbound is a validating, recursive, and caching DNS resolver." \
    UNBOUND_VERSION="1.24.0" \
    OPENSSL_VERSION="3.5.3" \
    BUILD_REVISION=0 \
    UNBOUND_UID="1000" \
    UNBOUND_GID="1000"

# Define shell
# Stage 1. Build Unbound with latest OpenSSL
## 1.1 Build OpenSSL
FROM --platform=$BUILDPLATFORM alpine:latest AS buildenv

# Set shell
SHELL ["/bin/sh", "-o", "pipefail", "-c"] 

# Define argument
ARG OPENSSL_VERSION

# Define environment variables
ENV OPENSSL_VERSION=${OPENSSL_VERSION} \
    OPENSSL_PGP="BA5473A2B0587B07FB27CF2D216094DFD0CB81EF" \
    OPENSSL_DOWNLOAD_URL="https://github.com/openssl/openssl/releases/download/openssl-"${OPENSSL_VERSION}"/openssl-"${OPENSSL_VERSION}".tar.gz"

    
WORKDIR /tmp/src

# Build OpenSSl from sources with checksum
RUN apk --no-cache --update add \
        ca-certificates \
        curl \
        file \
        gnupg \
    && apk --update add --no-cache --virtual .build-deps \
        build-base \
        perl \
        libevent-dev \
        libidn2-dev \
        linux-headers \
        apk-tools \
    && curl -sSL ${OPENSSL_DOWNLOAD_URL} -o openssl-${OPENSSL_VERSION}.tar.gz \
    && curl -sSL ${OPENSSL_DOWNLOAD_URL}.sha256 -o openssl-${OPENSSL_VERSION}.tar.gz.sha256 \
    && curl -sSL ${OPENSSL_DOWNLOAD_URL}.asc -o openssl-${OPENSSL_VERSION}.tar.gz.asc \
    && echo "`cat openssl-${OPENSSL_VERSION}.tar.gz.sha256`" | sha256sum -c - \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --no-tty --keyserver hkps://keys.openpgp.org --recv-keys ${OPENSSL_PGP} \
    && gpg --batch --verify openssl-${OPENSSL_VERSION}.tar.gz.asc openssl-${OPENSSL_VERSION}.tar.gz \
    && pkill -9 gpg-agent \
    && pkill -9 dirmngr \
    && tar xzf openssl-${OPENSSL_VERSION}.tar.gz \
    && rm openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./Configure \
        no-weak-ssl-ciphers \
        no-apps \
        no-docs \
        no-legacy \
        no-ssl3 \
        no-err \
        no-autoerrinit \
        enable-tfo \
        enable-quic \
        enable-ktls \
        enable-ec_nistp_64_gcc_128 \
        -fPIC \
        -DOPENSSL_NO_HEARTBEATS \
        -fstack-protector-strong \
        -fstack-clash-protection \
        --prefix=/usr/local/openssl \
        --openssldir=/usr/local/openssl \
        --libdir=/usr/local/openssl/lib \
    && make \
    && make install_sw \
    && apk del --no-cache .build-deps \
    && rm -rf \
        /usr/share/man \
        /usr/share/docs \
        /usr/local/openssl/bin \
        /tmp/* \
        /var/tmp/* \
        /var/log/* 

## 1.2 Build Unbound
# Define argument
ARG UNBOUND_VERSION \
    UNBOUND_UID \
    UNBOUND_GID

# Define environment
ENV UNBOUND_VERSION="${UNBOUND_VERSION}" \
    UNBOUND_DOWNLOAD_URL="https://www.nlnetlabs.nl/downloads/unbound/unbound-"${UNBOUND_VERSION}".tar.gz" \
    INTERNIC_PGP="F0CB1A326BDF3F3EFA3A01FA937BB869E3A238C5" \
    UNBOUND_PGP_WIJNGAARDS="EDFAA3F2CA4E6EB05681AF8E9F6F1C2D7E045F8D" \
    UNBOUND_PGP_GEORGE="948EB42322C5D00B79340F5DCFF3344D9087A490" \
    UNBOUND_UID="${UNBOUND_UID}" \
    UNBOUND_GID="${UNBOUND_GID}"

WORKDIR /tmp/src

# Build unbound from sources with checksum
RUN addgroup -S -g "${UNBOUND_GID}" _unbound \
    && adduser -S -H -h /usr/local/unbound -g _unbound -u "${UNBOUND_UID}" -D -G _unbound _unbound \
    && apk --update --no-cache add \
        ca-certificates \
        gnupg \
        curl \
        file \
        binutils \
    && apk --update --no-cache add --virtual .build-deps \
        build-base \
        libevent-dev \
        libsodium-dev \
        linux-headers \
        nghttp2-dev \
        ngtcp2-dev \
        expat-dev \
        protobuf-c-dev \
        hiredis-dev \
        bash \
    && curl -sSL ${UNBOUND_DOWNLOAD_URL} -o unbound.tar.gz \
    && curl -sSL ${UNBOUND_DOWNLOAD_URL}.asc -o unbound.tar.gz.asc \
    && curl -sSL ${UNBOUND_DOWNLOAD_URL}.sha256 -o unbound.tar.gz.sha256 \
    && echo "`cat unbound.tar.gz.sha256` unbound.tar.gz" | sha256sum -c - \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && gpg --no-tty --recv-keys "${UNBOUND_PGP_WIJNGAARDS}" "${UNBOUND_PGP_GEORGE}" \
    && gpg --batch --verify unbound.tar.gz.asc unbound.tar.gz \
    && tar -xzf unbound.tar.gz \
    && rm unbound.tar.gz \
    && cd unbound-"${UNBOUND_VERSION}" \
    && ./configure \
        --prefix=/usr/local/unbound/unbound.d/ \
        --with-run-dir=/usr/local/unbound/unbound.d \
        --with-conf-file=/usr/local/unbound/unbound.conf \
        --with-pidfile=/usr/local/unbound/unbound.d/unbound.pid \
        --mandir=/usr/share/man \
        --with-rootkey-file=/usr/local/unbound/iana.d/root.key \
        --with-ssl=/usr/local/openssl \
        --with-libevent \
        --with-libnghttp2 \
        --with-libhiredis \
        --with-username=_unbound \
        --disable-shared \
        --enable-dnstap \
        --enable-dnscrypt \
        --enable-cachedb \
        --enable-subnet \
        --with-pthreads \
        --without-pythonmodule \
        --without-pyunbound \
        --enable-event-api \
        --enable-tfo-server \
        --enable-tfo-client \
        --enable-pie \
        --enable-relro-now \
    && make \
    && make install \
    && mkdir -p "/usr/local/unbound/iana.d/" \
    && curl -sSL https://www.internic.net/domain/named.cache -o /usr/local/unbound/iana.d/root.hints \
    && curl -sSL https://www.internic.net/domain/named.cache.md5 -o /usr/local/unbound/iana.d/root.hints.md5 \
    && curl -sSL https://www.internic.net/domain/named.cache.sig -o /usr/local/unbound/iana.d/root.hints.sig \
    && echo "`cat /usr/local/unbound/iana.d/root.hints.md5` /usr/local/unbound/iana.d/root.hints" | md5sum -c - \
    && curl -sSL https://www.internic.net/domain/root.zone -o /usr/local/unbound/iana.d/root.zone \
    && curl -sSL https://www.internic.net/domain/root.zone.md5 -o /usr/local/unbound/iana.d/root.zone.md5 \
    && curl -sSL https://www.internic.net/domain/root.zone.sig -o /usr/local/unbound/iana.d/root.zone.sig \
    && echo "`cat /usr/local/unbound/iana.d/root.zone.md5` /usr/local/unbound/iana.d/root.zone" | md5sum -c - \
    && GNUPGHOME="$(mktemp -d)"\
    && export GNUPGHOME \
    && gpg --no-tty --recv-keys "$INTERNIC_PGP" \
    && gpg --verify /usr/local/unbound/iana.d/root.hints.sig /usr/local/unbound/iana.d/root.hints \
    && gpg --verify /usr/local/unbound/iana.d/root.zone.sig /usr/local/unbound/iana.d/root.zone \
    && /usr/local/unbound/sbin/unbound-anchor -v -a /usr/local/unbound/iana.d/root.key || true \
    && pkill -9 gpg-agent\
    && pkill -9 dirmngr

# Cleanup installation files
RUN rm -rf \
        /usr/local/unbound/unbound.conf \
        /usr/local/unbound/unbound.d/share \
        /usr/local/unbound/etc \
        /usr/local/unbound/iana.d/root.hints.* \
        /usr/local/unbound/iana.d/root.zone.* \
        /usr/local/unbound/unbound.d/include \
        /usr/local/unbound/unbound.d/lib \
    && find /usr/local/openssl/lib/libssl.so.* -type f | xargs strip --strip-all \
    && find /usr/local/openssl/lib/libcrypto.so.* -type f | xargs strip --strip-all \
    && strip --strip-all /usr/local/unbound/unbound.d/sbin/unbound \
    && strip --strip-all /usr/local/unbound/unbound.d/sbin/unbound-anchor \
    && strip --strip-all /usr/local/unbound/unbound.d/sbin/unbound-checkconf \
    && strip --strip-all /usr/local/unbound/unbound.d/sbin/unbound-control \
    && strip --strip-all /usr/local/unbound/unbound.d/sbin/unbound-host

# Create config files
COPY ./unbound/rootfs/ /

RUN mkdir -p \   
        /usr/local/unbound/conf.d/ \
        /usr/local/unbound/certs.d/ \
        /usr/local/unbound/zones.d/ \
        /usr/local/unbound/log.d/ \
    && touch /usr/local/unbound/log.d/unbound.log \
    && chown -R _unbound:_unbound \
        /usr/local/unbound/ \
    && ln -s /dev/random /dev/urandom /dev/null \
        /usr/local/unbound/unbound.d/ \
    && chown -Rh _unbound:_unbound \
        /usr/local/unbound/unbound.d/random \
        /usr/local/unbound/unbound.d/null \
        /usr/local/unbound/unbound.d/urandom \
    && chmod -R 755 \
        /usr/local/unbound/sbin/* \
    # enable root.hints and root.zone updated via crontab
    && (crontab -l 2>/dev/null; echo "0 0 * * 0 /bin/bash /usr/local/unbound/sbin/01-update_root_hints.sh && unbound-control reload") | crontab - \
    && (crontab -l 2>/dev/null; echo "0 0 * * 0 /bin/bash /usr/local/unbound/sbin/01-update_root_zone.sh && unbound-control reload") | crontab - \
    && (crontab -l 2>/dev/null; echo "5 0 * * 0 /bin/bash /usr/local/unbound/sbin/02-check_signature.sh && unbound-control reload") | crontab -

# Install dependencies
RUN apk --update --no-cache add \
        ca-certificates \
        # to update root.*
        curl \
        gpg \
        perl \
        # to tune unbound conf
        coreutils \
        libattr \
        utmps-libs \
        skalibs-libs \
        # to execute unbound
        expat \
        protobuf-c \
        libsodium \
        nghttp2 \
        libevent \
        hiredis \
        ngtcp2 \
        # for timezone
        tzdata \
        # for dig
        drill \
        tini \
        # to execute unbound.sh
        shadow \
        su-exec \
        bash \
    #cleanup
    && rm -rf /tmp/* /var/cache/apk/*

# Stage 2 Assemble for target platform
## 2.1 Finalize
FROM scratch AS stage

COPY --from=buildenv /usr/local/unbound/ \
        /app/usr/local/unbound  
COPY --from=buildenv /etc/crontabs/root \
        /app/etc/crontabs/root

COPY --from=buildenv /lib/*-musl-* \
        /app/lib/

COPY --from=buildenv /bin/sh /bin/sed /bin/grep /bin/netstat /bin/chown /bin/chgrp \
        /app/bin/
  
COPY --from=buildenv /sbin/su-exec /sbin/tini \
        /app/sbin/
  
# for changing user
COPY --from=buildenv /usr/sbin/groupmod /usr/sbin/usermod \
        /app/usr/sbin/

# for root.* updated
COPY --from=buildenv /usr/bin/curl /usr/bin/gpg /usr/bin/dirmngr /usr/bin/md5sum /usr/bin/nproc /usr/bin/perl \
        /app/usr/bin/
    
# for tuning unbound
COPY --from=buildenv  /usr/bin/nproc /usr/bin/perl \
        /app/usr/bin/
COPY --from=buildenv /usr/lib/libacl* /usr/lib/libattr* /usr/lib/libutmps*  /usr/lib/libskarnet* \
        /app/usr/lib/
COPY --from=buildenv  /usr/lib/perl5/core_perl/CORE/libperl* \
        /app/usr/lib/perl5/core_perl/CORE/

# for healthcheck.sh
COPY --from=buildenv /usr/bin/awk /usr/bin/drill /usr/bin/id \
        /app/usr/bin/

# for Openssl
COPY --from=buildenv /usr/local/openssl/lib/libssl.so.* /usr/local/openssl/lib/libcrypto.so.* \
        /app/lib/
  
COPY --from=buildenv /usr/lib/libgcc_s* \
        /usr/lib/libbsd* \ 
        /usr/lib/libmd* \
        /usr/lib/libsodium* \
        /usr/lib/libexpat* \
        /usr/lib/libprotobuf-c* \
        /usr/lib/libnghttp2* \
        /usr/lib/libldns* \
        /usr/lib/libhiredis* \
        /usr/lib/libevent* \
        /usr/lib/libngtcp2* \
        /app/usr/lib/
 
COPY --from=buildenv /etc/ssl/ \
        /app/etc/ssl/

# user and groups
COPY --from=buildenv /etc/passwd /etc/group \
        /app/etc/
  
# timezone
COPY --from=buildenv /usr/share/zoneinfo/ \
        /app/usr/share/zoneinfo/

### Permission
# entrypoint
COPY --from=buildenv --chmod=755 /entrypoint \
        /app/

# # healthcheck
# COPY --from=buildenv --chmod=755 /usr/local/unbound/sbin/healthcheck.sh \
#         /app/usr/local/unbound/sbin/healthcheck.sh

## 2.2 Assemble unbound container
FROM scratch AS unbound

ARG UNBOUND_VERSION \
    BUILD_REVISION \
    BUILD_NAME \
    BUILD_DESCRIPTION \
    BUILD_REPOSITORY

ENV UNBOUND_HEALTHCHECK_PORT=${UNBOUND_HEALTHCHECK_PORT} \
    DISABLE_SET_PERMS=${DISABLE_SET_PERMS} \
    UNBOUND_UID=${UNBOUND_UID} \
    UNBOUND_GID=${UNBOUND_GID} \
    TZ=${TZ} \
    PATH=/usr/local/unbound/unbound.d/sbin:/usr/local/sbin/:"$PATH" 

WORKDIR /

VOLUME [ "/usr/local/unbound"]

COPY --from=stage /app/ /

HEALTHCHECK --interval=30s --timeout=15s --start-period=5s CMD sh /usr/local/unbound/sbin/healthcheck.sh 

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint"]

LABEL maintainer="megavolts <marc.oggier@megavolts.ch>"\
      org.opencontainers.image.arch="${TARGETARCH}" \
      org.opencontainers.image.version=${UNBOUND_VERSION}-${BUILD_REVISION} \
      org.opencontainers.image.title="BUILD_NAME"-app \
      org.opencontainers.image.description="BUILD_DESCRIPTION" \
      org.opencontainers.image.url="https://github.com/"${BUILD_REPOSITORY} \
      org.opencontainers.image.vendor="Marc Oggier" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/"${BUILD_REPOSITORY}