ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-controller-config-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=api \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Controller Configuration API" \
      description="Controller Configuration API provides a REST API to an orchestration system." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

# contrail-config/html/* -> contrail-config/html/*
COPY --from=build /root/contrail/buildroot/usr/share/doc/contrail-config/doc/source/contrail-config/html /usr/share/doc/contrail-config/doc/source/contrail-config/html
# schema_transformer is required to be able to run db_manage
RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail-api-server==0.1.dev0" "vnc_openstack==0.1.dev0" "contrail_issu==0.1.dev0" "schema_transformer==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
