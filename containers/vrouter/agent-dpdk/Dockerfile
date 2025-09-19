ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-vrouter-base:${CONTRAIL_CONTAINER_TAG}

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV SERVICE_NAME=agent-dpdk \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail DPDK poll mode driver" \
      description="DPDK support for Contrail vrouter agent" \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/contrail/buildroot/usr/bin/contrail-vrouter-dpdk /usr/bin/
COPY --from=build /root/contrail/buildroot/usr/bin/dpdk_nic_bind.py /usr/bin/
COPY --from=build /root/contrail/buildroot/opt/contrail/ddp/mplsogreudp.pkg /opt/contrail/ddp/

RUN set -e ; \
    source /functions.sh && \
    download_package https://downloadmirror.intel.com 30590/eng/800_series_comms_binary_package_1.3.30.0.zip /usr/tmp/downloaded_ice_comms-1.3.30.0.zip && \
    cd /usr/tmp && \
    yum -y install unzip && \
    unzip -o -d /usr/tmp downloaded_ice_comms-1.3.30.0.zip && \
    unzip -o -d /usr/tmp/ice-1.3.30.0 ice_comms-1.3.30.0.zip && \
    mkdir -p /lib/firmware/updates/intel/ice/ddp && \
    cp /usr/tmp/ice-1.3.30.0/ice_comms-1.3.30.0.pkg /lib/firmware/updates/intel/ice/ddp/ && \
    cp /usr/tmp/ice-1.3.30.0/ice.pkg /lib/firmware/updates/intel/ice/ddp/ && \
    cd /lib/firmware/updates/intel/ice/ddp && \
    ln -sf ice_comms-1.3.30.0.pkg ice.pkg && \
    rm -rf /usr/tmp/*ice*

RUN \
    yum install -y dhclient which liburcu2 userspace-rcu libnl3 numactl-libs rdma-core==47mlnx1-1.47329 libibverbs==47mlnx1-1.47329 ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    ldconfig

COPY entrypoint.sh /
COPY *_defs /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-vrouter-dpdk"]
