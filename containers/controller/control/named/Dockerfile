ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-controller-control-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV SERVICE_NAME=named \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Named" \
      description="Contrail Named complements Contrail DNS service." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-named /usr/bin/contrail-named
COPY --from=build ${BUILD_ROOT}/usr/lib/libisc*so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libdns*so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libns*so /usr/lib/

COPY entrypoint.sh /

RUN set -e ; \
    if [ ! -f /etc/authbind/byport/53 ]; then \
        touch /etc/authbind/byport/53 ; \
        chown contrail. /etc/authbind/byport/53 ; \
        chmod 0755 /etc/authbind/byport/53 ; \
    fi ; \
    ldconfig

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-named","-f","-u","contrail","-c","/etc/contrail/dns/contrail-named.conf"]
