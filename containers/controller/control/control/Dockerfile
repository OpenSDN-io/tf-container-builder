ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-controller-control-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV SERVICE_NAME=control \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Controller" \
      description="Contrail Control is xmpp/bgp based routing engine for Contrail." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/work/build/production/control-node/contrail-control /usr/bin/contrail-control

COPY entrypoint.sh /

# cap_net_bind_service for bgp port 179
RUN set -e ; \
    if [ ! -f /etc/authbind/byport/179 ]; then \
        touch /etc/authbind/byport/179 ; \
        chown contrail. /etc/authbind/byport/179 ; \
        chmod 0755 /etc/authbind/byport/179 ; \
    fi

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-control"]
