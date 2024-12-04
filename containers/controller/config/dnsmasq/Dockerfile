ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV NODE_TYPE=config \
    SERVICE_NAME=dnsmasq \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Dnsmasq" \
      description="Contrail Dnsmasq provides network infrastructure: DNS, DHCP, router advertisement and network boot." \
      $VENDOR_DOMAIN".pod"=$NODE_TYPE \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

RUN mkdir -p /etc/scripts/

COPY entrypoint.sh /
COPY conf/* /etc/scripts/

RUN set -e ; \
    yum install -y gcc make xz && \
    source /functions.sh && \
    download_package https://thekelleys.org.uk dnsmasq/dnsmasq-2.90.tar.xz dnsmasq-2.90.tar.xz "--no-check-certificate" && \
    tar -xvf dnsmasq-2.90.tar.xz && \
    rm -f dnsmasq-2.90.tar.xz && \
    pushd dnsmasq-2.90 && \
    make && \
    make install && \
    popd && \
    rm -rf dnsmasq-2.90 && \
    yum autoremove -y gcc make && \
    echo "conf-dir=/etc/dnsmasq,*.conf" > /etc/dnsmasq.conf && \
    yum clean all -y && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
CMD ["dnsmasq", "-k", "-p0"]
