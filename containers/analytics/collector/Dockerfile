ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-analytics-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV SERVICE_NAME=collector \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Analytics Collector" \
      description="Contrail Analytics Collector collects the running state of different processes sent by other nodes." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

COPY --from=build /root/work/build/production/analytics/vizd /usr/bin/contrail-collector
RUN set -e ; \
    source /etc/os-release && \
    ver=$(echo $VERSION_ID | cut -d '.' -f 1) ; \
    if [[ ${ver} == 9 ]]; then \
        pkgs="boost" ; \
    else \
        pkgs="boost169" ; \
    fi ; \
    yum install -y $pkgs protobuf redis cassandra-cpp-driver libzookeeper librdkafka1 ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-collector"]
