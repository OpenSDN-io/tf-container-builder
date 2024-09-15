ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=analytics
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

# TODO: Remove pip install
RUN sed -e '/^tsflags=nodocs/d' -i /etc/yum.conf && \
    yum install -y python3-devel gcc kernel-devel kernel-headers make diffutils file && \
    python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install pip install gevent==22.10.1 && \
    python3 -m pip install redis psutil future futures bottle xmltodict lxml sseclient requests prettytable consistent-hash kombu fysom "netaddr<1" && \
    yum install -y contrail-analytics && \
    yum clean all -y && \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
