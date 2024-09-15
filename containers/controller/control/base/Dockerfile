ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=control
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

RUN yum install -y contrail-control contrail-dns 2>&1 | tee /tmp/log ; \
    grep -i "error:" /tmp/log && exit 1 ; \
    mkdir -p /opt/contrail_dns ; \
    cp -r /etc/contrail/dns/* /opt/contrail_dns/ ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
