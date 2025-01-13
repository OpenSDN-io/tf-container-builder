ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-analytics-snmp-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=topology \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="SNMP Topology" \
      description="SNMP Topology periodically updates topology table, which is used by UI to draw maps." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "tf_topology==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/tf-topology", "-c", "/etc/contrail/tf-topology.conf"]
