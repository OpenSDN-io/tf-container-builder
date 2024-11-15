ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-general-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Init container for OpenStack Heat" \
      description="Sidecar container with libraries for heat services." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

RUN \
    mkdir -p /opt/contrail/site-packages && \
    rpm -Uvh --nodeps $(repoquery -q --location python3-contrail) && \
    rpm -Uvh --nodeps $(repoquery -q --location contrail-heat) && \
    cp -rf /usr/lib/python3.6/site-packages/contrail_heat* /opt/contrail/site-packages && \
    cp -rf /usr/lib/python3.6/site-packages/vnc_api* /opt/contrail/site-packages && \
    cp -rf /usr/lib/python3.6/site-packages/cfgm_common* /opt/contrail/site-packages && \
    yum autoremove -y python3-contrail contrail-heat && \
    yum clean all -y && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
