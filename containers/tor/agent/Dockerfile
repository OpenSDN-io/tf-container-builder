ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV NODE_TYPE=toragent \
    SERVICE_NAME=tor-agent \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail ToR agent" \
      description="A ToR agent provisioned in the Contrail cluster acts as the OVSDB client for the ToR switch, and all of the OVSDB interactions with the ToR switch are performed by using the ToR agent." \
      $VENDOR_DOMAIN".pod"=$NODE_TYPE \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

RUN set -e ; \
    yum install -y contrail-vrouter-agent ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail-vrouter-api==0.1.dev0" ; \
    rm -rf /root/.cache

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-tor-agent","--config_file","/etc/contrail/contrail-tor-agent.conf"]
