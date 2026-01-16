ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ENV NODE_TYPE=vrouter
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/bin/tools/vif /usr/bin/
COPY --from=build ${BUILD_ROOT}/usr/bin/tools/qosmap /usr/bin/

# removing network-scripts: this folder will mounted from the host (or not used in Ubuntu) so the one installed by initscripts package in container is removed.
RUN set -e ; \
    source /etc/os-release ; \
    dnf install -y NetworkManager initscripts ethtool pciutils ; \
    dnf clean all -y ; \
    if [[ "$ID" == 'rhel' && "${PLATFORM_ID//*:/}" == 'el8' ]] ; then \
        rm -f /usr/sbin/ifup /usr/sbin/ifdown && \
        cp /etc/sysconfig/network-scripts/ifup /etc/sysconfig/network-scripts/ifdown /usr/sbin/ ; \
    fi ; \
    mkdir -p /opt/contrail ; \
    cp -r /etc/sysconfig/network-scripts /opt/contrail/ ; \
    rm -rf /var/cache/yum /etc/sysconfig/network-scripts ; \
    ldconfig

COPY *.sh ifup-* ifdown-* network-functions-vrouter* dhclient-vhost0.conf /

CMD ["/usr/bin/tail","-f","/dev/null"]
