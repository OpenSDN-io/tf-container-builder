ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-analytics-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV NODE_TYPE=database \
    SERVICE_NAME=query-engine \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Query Engine" \
      description="Contrail Query Engine handles the queries to access data from Analytics DB." \
      $VENDOR_DOMAIN".pod"=$NODE_TYPE \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

ARG BUILD_ROOT
# cassandra-cpp-driver of version 2.17.1 has bug with callbacks, doesn't work
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-query-engine /usr/bin/contrail-query-engine

RUN set -e ; \
    source /etc/os-release && \
    ver=$(echo $VERSION_ID | cut -d '.' -f 1) ; \
    if [[ ${ver} == 9 ]]; then \
        pkgs="boost" ; \
    else \
        pkgs="boost169" ; \
    fi ; \
    dnf install -y $pkgs protobuf redis cassandra-cpp-driver libzookeeper librdkafka ; \
    dnf clean all -y ; \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-query-engine","--conf_file","/etc/contrail/contrail-query-engine.conf"]
