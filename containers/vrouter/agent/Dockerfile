ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-vrouter-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=agent \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Vrouter Agent" \
      description="The vRouter agent is a user space process running inside Linux. It acts as the local, lightweight control plane." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/lib/libisc-9.21.3.so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libisccc-9.21.3.so /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/libisccfg-9.21.3.so /usr/lib/

COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-vrouter-agent /usr/bin/
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail-vrouter-agent-health-check.py /usr/bin/
COPY --from=build ${BUILD_ROOT}/usr/bin/contrail_crypt_tunnel_client.py /usr/bin/
COPY --from=build ${BUILD_ROOT}/Version /contrail_build_version

# COPY copies content instead of symlink - create symlinks manually
# sudo is needed for vrouter-netns
RUN set -e ; \
    ln -s /usr/lib/libisc-9.21.3.so /usr/lib/libisc.so ; \
    ln -s /usr/lib/libisccc-9.21.3.so /usr/lib/libisccc.so ; \
    ln -s /usr/lib/libisccfg-9.21.3.so /usr/lib/libisccfg.so ; \
    ldconfig ; \
    source /etc/os-release && \
    ver=$(echo $VERSION_ID | cut -d '.' -f 1) ; \
    if [[ ${ver} == 9 ]]; then \
        pkgs="boost" ; \
    else \
        pkgs="boost169" ; \
    fi ; \
    dnf install -y $pkgs sudo gperftools-libs iptables dhclient haproxy libvirt-client ; \
    dnf clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail-vrouter-api==0.1.dev0" "opencontrail-vrouter-netns==0.1.dev0" ; \
    rm -rf /root/.cache

COPY *.sh /
# /etc/dhcp/dhclient-script is allowed by apparmor to execute
COPY vhost0-dhcp/dhclient-script /etc/dhcp/dhclient-script
COPY vhost0-dhcp/vhost0-nameservers.sh /etc/dhcp/dhclient-exit-hooks.d/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-vrouter-agent"]
