ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=analytics-snmp
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/share/mibs/netsnmp /usr/share/mibs/netsnmp

# required to install python's snmp package
RUN set -e ; \
    dnf install -y "net-snmp-devel-1:5.9.1-17.el9" ; \
    dnf clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
