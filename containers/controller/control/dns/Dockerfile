ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-controller-control-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV SERVICE_NAME=dns \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail DNS" \
      description="Contrail DNS provides DNS service to the VMs spawned on compute nodes." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-dns /usr/bin/contrail-dns
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-rndc /usr/bin/contrail-rndc
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-rndc-confgen /usr/bin/contrail-rndc-confgen
COPY --from=build ${BUILD_ROOT}/usr/bin/applynamedconfig.py /etc/contrail/dns/applynamedconfig.py
# libs for contrail-rndc
COPY --from=build ${BUILD_ROOT}/usr/lib/libisc*so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libdns*so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libns*so /usr/lib/

COPY entrypoint.sh /

RUN set -e ; \
    ldconfig

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-dns"]
