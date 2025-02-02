ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=analytics-snmp
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

# required to install python's snmp package
RUN yum install -y net-snmp-devel ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
