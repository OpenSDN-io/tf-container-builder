ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV NODE_TYPE=toragent \
    SERVICE_NAME=tor-agent \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail ToR agent" \
      description="A ToR agent provisioned in the Contrail cluster acts as the OVSDB client for the ToR switch, and all of the OVSDB interactions with the ToR switch are performed by using the ToR agent." \
      $VENDOR_DOMAIN".pod"=$NODE_TYPE \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/contrail/buildroot/usr/lib/libisc-9.21.3.so /usr/lib/
COPY --from=build /root/contrail/buildroot/usr/lib/libisccc-9.21.3.so /usr/lib/
COPY --from=build /root/contrail/buildroot/usr/lib/libisccfg-9.21.3.so /usr/lib/

# TODO: restore it for rocky9 build
#COPY --from=build /root/contrail/buildroot/usr/bin/contrail-tor-agent /usr/bin/
COPY --from=build /root/contrail/buildroot/usr/bin/contrail-vrouter-agent-health-check.py /usr/bin/
COPY --from=build /root/contrail/buildroot/usr/bin/contrail_crypt_tunnel_client.py /usr/bin/

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
    yum install -y $pkgs gperftools-libs ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail-vrouter-api==0.1.dev0" ; \
    rm -rf /root/.cache

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-tor-agent","--config_file","/etc/contrail/contrail-tor-agent.conf"]
