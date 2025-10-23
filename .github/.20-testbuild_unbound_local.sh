BUILD_DATE=$(cat buildvars | grep BUILD_DATE  | cut -d= -f2)
UNBOUND_VERSION=$(cat buildvars | grep UNBOUND_VERSION  | cut -d= -f2)
OPENSSL_DOCKERBUILDENV_VERSION=$(cat buildvars | grep OPENSSL_DOCKERBUILDENV_VERSION  | cut -d= -f2)
DOCKER_IMAGE_VERSION=$(cat buildvars | grep DOCKER_IMAGE_VERSION  | cut -d= -f2)

echo "Building docker image $DOCKER_IMAGE_VERSION with openssl build env $OPENSSL_DOCKERBUILDENV_VERSION and unbound $UNBOUND_VERSION on $BUILD_DATE"

docker buildx build ./unbound -t megavolts/unbound:test --load --no-cache \
    --build-arg BUILD_IMAGE_VERSION=$DOCKER_IMAGE_VERSION \
    --build-arg TARGETPLATFORM=linux/amd64 \
    --build-arg UNBOUND_VERSION=$UNBOUND_VERSION \
    --build-arg BUILD_DATE=$BUILD_DATE \
    --build-arg OPENSSL_DOCKERBUILDENV_VERSION=$OPENSSL_DOCKERBUILDENV_VERSION