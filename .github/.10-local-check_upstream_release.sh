#!/bin/sh

FORCE=true

BOOL="$(curl -s https://api.github.com/repos/NLnetLabs/unbound/releases | jq '.[0] | .prerelease')"
if $BOOL; then
    echo "Pre-release, skipping"
    exit 1
else
    UNBOUND_VERSION="$(curl -s https://api.github.com/repos/NLnetLabs/unbound/releases | jq '.[0] | .name' -r | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)"
fi

# OpenSSL Docker Build Environement
OPENSSL_VERSION="$(curl -s https://api.github.com/repos/megavolts/openssl-dockerbuildenv/releases | jq '.[0] | .name' -r | grep -Eo '([0-9]+)(\.?[0-9]+)*' | head -1)" 
OPENSSL_DOCKERBUILDENV_VERSION="$(curl -s https://api.github.com/repos/megavolts/openssl-dockerbuildenv/releases | jq '.[0] | .name' -r)" 

# Get current docker build version from previous buildvars
UNBOUND_DOCKER_VERSION="$(curl -s https://raw.githubusercontent.com/megavolts/unbound-docker/refs/heads/main/buildvars | awk '/^UNBOUND_VERSION=/' | cut -d= -f2)"  
OPENSSL_DOCKER_VERSION="$(curl -s https://raw.githubusercontent.com/megavolts/unbound-docker/refs/heads/main/buildvars | awk '/^OPENSSL_DOCKERBUILDENV_VERSION=/' | cut -d= -f2 | cut -d- -f1)"  
BUILD_REVISION="$(curl -s https://raw.githubusercontent.com/megavolts/unbound-docker/refs/heads/main/buildvars | awk '/^DOCKER_IMAGE_VERSION=/' | cut -d- -f2)"

# Check if update is available
if ! [[ "$UNBOUND_VERSION" = "$UNBOUND_DOCKER_VERSION" ]]; then
    echo "Update found for Unbound ($UNBOUND_VERSION)"
    BUILD_REVISION=0
elif ! [[ "$OPENSSL_VERSION" = "$OPENSSL_DOCKER_VERSION" ]]; then
    echo  "Update found for OpenSSL ($OPENSSL_VERSION)"
    BUILD_REVISION="$(( $BUILD_REVISION +1 ))" 
elif [[ "$FORCE" ]]; then
    echo  "Force build"
    UNBOUND_VERSION=$UNBOUND_DOCKER_VERSION
    OPENSSL_VERSION=$OPENSSL_DOCKER_VERSION
    BUILD_REVISION="$(( $BUILD_REVISION +1 ))" 
else
    echo "No update found"
fi 

BUILD_IMAGE_VERSION=$UNBOUND_VERSION-$BUILD_REVISION
echo "Next Unbound docker image build number is $BUILD_IMAGE_VERSION"

