ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-controller-config-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=schema \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail VNC Configuration Schema Transformer" \
      description="Contrail Schema Transformer compiles the high level, intent based data model into a low level configuration data model." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "schema_transformer==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/contrail-schema", "--conf_file", "/etc/contrail/contrail-schema.conf", "--conf_file", "/etc/contrail/contrail-keystone-auth.conf"]
