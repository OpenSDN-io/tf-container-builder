FROM redis:6.0.19

ARG VENDOR_NAME
ARG VENDOR_DOMAIN

ARG CONTAINER_NAME
ARG CONTRAIL_CONTAINER_TAG

ARG LC_ALL="en_US.UTF-8"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"

# These definitions are just for build purposes and must not be changed at runtime
ENV VENDOR_DOMAIN=$VENDOR_DOMAIN \
    VENDOR_NAME=$VENDOR_NAME \
    CONTRAIL_GID=1999 \
    CONTRAIL_UID=1999 \
    CONTRAIL_USER=contrail \
    CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG \
    LC_ALL=$LC_ALL \
    LANG=$LANG \
    LANGUAGE=$LANGUAGE \
    SERVICE_NAME=redis \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Contrail Redis" \
      description="Contrail Redis server supports query engine." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY __licensing.txt /licenses/licensing.txt

COPY *.sh /

RUN set -e ; \
    /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done' ; \
    export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update || /bin/true ; \
    apt-get -y install python3-minimal ; \
    groupadd --gid $CONTRAIL_GID --system $CONTRAIL_USER ; \
    usermod -a -G $CONTRAIL_GID redis ; \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/contrail-entrypoint.sh"]

CMD ["redis-server"]

ENV CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG