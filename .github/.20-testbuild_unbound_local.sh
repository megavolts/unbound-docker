APP=unbound
BUILD_DATE=$(cat buildvars | grep BUILD_DATE  | cut -d= -f2)
UNBOUND_VERSION=$(cat buildvars | grep UNBOUND_VERSION  | cut -d= -f2)
OPENSSL_DOCKERBUILDENV_VERSION=$(cat buildvars | grep OPENSSL_DOCKERBUILDENV_VERSION  | cut -d= -f2)
DOCKER_IMAGE_VERSION=$(cat buildvars | grep DOCKER_IMAGE_VERSION  | cut -d= -f2)

 # Check if BUILD_VERSION is already released
# Check for latest released
if [[ $(curl -s https://api.github.com/repos/megavolts/$APP-docker/releases | grep "status" | cut -d\" -f4) = 404 ]];
    then
    echo "No release existing"
else
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/megavolts/$APP-docker/releases | jq '.[0] | .name' -r)
    BUILD_VERSION=$( echo $DOCKER_IMAGE_VERSION | cut -d- -f1)
    BUILD_REVISION=$( echo $DOCKER_IMAGE_VERSION | cut -d- -f2)
    if [[ $LATEST_RELEASE = $DOCKER_IMAGE_VERSION ]];
        then
        echo "Release $DOCKER_IMAGE_VERSION already exist. Updated build version with next revision"
        BUILD_REVISION=$(( $BUILD_REVISION +1 ))
        DOCKER_IMAGE_VERSION=$BUILD_VERSION-$BUILD_REVISION
    else
        echo "No new release. Rebuilding with incremented version number."
        BUILD_REVISION=$( echo $DOCKER_IMAGE_VERSION | cut -d- -f2)
        BUILD_REVISION=$(( $BUILD_REVISION +1 ))
    fi
    DOCKER_IMAGE_VERSION=$BUILD_VERSION-$BUILD_REVISION
fi

echo "Building docker image $DOCKER_IMAGE_VERSION"
echo "  - OpenSSL version: $OPENSSL_DOCKERBUILDENV_VERSION"
echo "  - Unbound version: $UNBOUND_VERSION"


docker buildx build ./unbound -t megavolts/unbound:local -t megavolts/unbound:latest --load \
    --build-arg BUILD_IMAGE_VERSION=$DOCKER_IMAGE_VERSION \
    --build-arg TARGETPLATFORM=linux/amd64 \
    --build-arg UNBOUND_VERSION=$UNBOUND_VERSION \
    --build-arg BUILD_DATE=$BUILD_DATE \
    --build-arg OPENSSL_DOCKERBUILDENV_VERSION=$OPENSSL_DOCKERBUILDENV_VERSION