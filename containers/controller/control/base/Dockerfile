ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=control
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

RUN set -e ; \
    yum install -y contrail-control contrail-dns ; \
    mkdir -p /opt/contrail_dns ; \
    cp -r /etc/contrail/dns/* /opt/contrail_dns/ ; \
    chown -R contrail:contrail /etc/contrail/ ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
