ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Init container" \
      description="Container is used to configure operating system for Contrail services." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
