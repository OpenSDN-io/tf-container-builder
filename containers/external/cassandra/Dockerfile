FROM cassandra:3.11

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
    SERVICE_NAME=cassandra \
    CONTAINER_NAME=$CONTAINER_NAME

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Contrail Cassandra DB" \
      description="Configuration database for Contrail Controller." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY __licensing.txt /licenses/licensing.txt

ENV CASSANDRA_HOME=/opt/cassandra \
# Add required license as text file in Liceses directory
    CASSANDRA_CONFIG=/etc/cassandra \
    CASSANDRA_LIB=/var/lib/cassandra \
    CASSANDRA_LOG=/var/log/cassandra \
    CASSANDRA_USER=cassandra \
    CASSANDRA_GROUP=cassandra \
    CASSANDRA_UID=2000 \
    CASSANDRA_GID=2000 \
    PATH="/opt/cassandra/bin:$PATH" \
    CASSANDRA_REAPER_CONFIG=/etc/cassandra-reaper

COPY *.sh /

RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done' ; \
    export DEBIAN_FRONTEND=noninteractive ; \
    apt-get update || /bin/true ; \
    apt-get -y install python3-minimal ; \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* ; \
    # save original config
    cp ${CASSANDRA_CONFIG}/cassandra.yaml ${CASSANDRA_CONFIG}/cassandra.origin ; \
    cp ${CASSANDRA_CONFIG}/jvm.options ${CASSANDRA_CONFIG}/jvm.options.origin


ENTRYPOINT ["/contrail-entrypoint.sh"]

CMD ["cassandra", "-f"]
