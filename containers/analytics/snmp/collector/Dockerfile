ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-analytics-snmp-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=snmp-collector \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="SNMP Collector" \
      description="SNMP Collector collects data from switches(Spine/Leaf)." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "tf_snmp_collector==0.1.dev0"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/tf-snmp-collector", "-c", "/etc/contrail/tf-snmp-collector.conf", "--device-config-file", "/etc/contrail/device.ini"]
