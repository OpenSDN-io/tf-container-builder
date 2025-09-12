ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=analytics-snmp
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

COPY --from=build /root/contrail/build/usr/share/mibs/netsnmp /usr/share/mibs/netsnmp
# required to install python's snmp package
RUN set -e ; \
    yum install -y net-snmp-devel ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
