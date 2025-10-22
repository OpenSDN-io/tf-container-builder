FROM apache/kafka:3.9.1

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
    SERVICE_NAME=kafka \
    CONTAINER_NAME=$CONTAINER_NAME

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Contrail Kafka" \
      description="Contrail Kafka is used for streaming data in Analytics DB." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ENV KAFKA_DIR=/opt/kafka \
    KAFKA_CONF_DIR=/opt/kafka/config \
    LOG_DIR=/var/log/kafka \
    KAFKA_USER=appuser \
    KAFKA_GROUP=appuser

USER 0

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY __licensing.txt /licenses/licensing.txt

COPY *.sh /

RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done' ; \
    apk add --no-cache python3

ENTRYPOINT ["/cacert_entrypoint.sh"]
WORKDIR ${KAFKA_DIR}
CMD ["/contrail-entrypoint.sh"]