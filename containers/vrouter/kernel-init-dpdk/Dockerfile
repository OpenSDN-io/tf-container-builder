ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-vrouter-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Kernel init container for vrouter in DPDK mode" \
      description="Prepares the host operating system for the contrail vrouter dpdk interface." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
