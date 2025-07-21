FROM rabbitmq:3.10.7-management

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
    SERVICE_NAME=rabbitmq \
    RABBITMQ_LOGS=- \
    RABBITMQ_SASL_LOGS=- \
    CONTAINER_NAME=$CONTAINER_NAME

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Contrail RabbitMQ" \
      description="Contrail Rabbitmq is the message bus that different Contrail processes subscribe to." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY __licensing.txt /licenses/licensing.txt

COPY *.sh /

# due to changes in debian repos apt-transport-https is needed for
# update but it can't be installed without update. thus error in
# first update should be ignored.
RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done' && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update || /bin/true && \
    apt-get -fy install bind9-host xxd && \
    groupadd --gid $CONTRAIL_GID --system $CONTRAIL_USER && \
    usermod -a -G $CONTRAIL_GID rabbitmq

ENTRYPOINT ["/contrail-entrypoint.sh"]

CMD ["rabbitmq-server"]

ENV CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG
