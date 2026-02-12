APP=unbound
BUILD_DATE=$(cat buildvars | grep BUILD_DATE  | cut -d= -f2)
UNBOUND_VERSION=$(cat buildvars | grep UNBOUND_VERSION  | cut -d= -f2)
OPENSSL_DOCKERBUILDENV_VERSION=$(cat buildvars | grep OPENSSL_DOCKERBUILDENV_VERSION  | cut -d= -f2)
DOCKER_IMAGE_VERSION=$(cat buildvars | grep DOCKER_IMAGE_VERSION  | cut -d= -f2)

# TODO check if REVISION EXISTS
# Check if BUILD_VERSION is already released
# Check for latest released
if [[ $(curl -s https://api.github.com/repos/megavolts/$APP-docker/releases | grep "status" | cut -d\" -f4) = 404 ]];
    then
    echo "No release existing"
else
    LATEST_RELEASE=$(curl -s https://api.github.com/repos/megavolts/$APP-docker/releases | jq '.[0] | .name' -r)

    if [[ $LATEST_RELEASE = $BUILD_IMAGE_VERSION ]];
        then
        echo "Release $BUILD_IMAGE_VERSION already exist. Updated build version with next revision"
        BUILD_VERSION=$( echo $BUILD_IMAGE_VERSION | cut -d- -f1)
        BUILD_REVISION=$( echo $BUILD_IMAGE_VERSION | cut -d- -f2)
        BUILD_REVISION=$(( $BUILD_REVISION +1 ))
        BUILD_IMAGE_VERSION=$BUILD_VERSION-$BUILD_REVISION
    fi
fi

echo "Building docker image $DOCKER_IMAGE_VERSION with openssl build env $OPENSSL_DOCKERBUILDENV_VERSION and unbound $UNBOUND_VERSION on $BUILD_DATE"

docker buildx build ./unbound -t megavolts/unbound:local -t megavolts/unbound:latest --load \
    --build-arg BUILD_IMAGE_VERSION=$DOCKER_IMAGE_VERSION \
    --build-arg TARGETPLATFORM=linux/amd64 \
    --build-arg UNBOUND_VERSION=$UNBOUND_VERSION \
    --build-arg BUILD_DATE=$BUILD_DATE \
    --build-arg OPENSSL_DOCKERBUILDENV_VERSION=$OPENSSL_DOCKERBUILDENV_VERSION