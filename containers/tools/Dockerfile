ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="A common tool for debugging" \
      description="The image contains scripts to debug Contrail processes." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/bin/tools/* /usr/bin/
COPY --from=build ${BUILD_ROOT}/usr/share/lua/5.1 /usr/share/lua/5.1
COPY --from=build ${BUILD_ROOT}/usr/local/share/wireshark/init.lua /usr/local/share/wireshark/init.lua
COPY --from=build ${BUILD_ROOT}/usr/local/lib64/wireshark/plugins/*.lua /usr/local/lib64/wireshark/plugins/

# tshark is needed for sandump tool which is included into contrail-tools package
RUN set -e ; \
      source /etc/os-release ; \
      dnf install -y sudo openssh-clients bzip2 tcpdump wireshark socat; \
      dnf clean all -y ; \
      rm -rf /var/cache/yum ; \
      ln -s /usr/bin/tshark /usr/sbin/tshark3_2

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "

ENTRYPOINT ["/bin/bash"]
