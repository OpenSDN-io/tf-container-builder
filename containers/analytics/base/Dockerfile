ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=analytics
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

# TODO: Remove pip install
RUN sed -e '/^tsflags=nodocs/d' -i /etc/yum.conf ; \
    yum install -y contrail-analytics 2>&1 | tee /tmp/log ; \
    grep -i "error:" /tmp/log && exit 1 ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

CMD ["/usr/bin/tail","-f","/dev/null"]
