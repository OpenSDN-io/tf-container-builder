ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-general-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Init container for OpenStack Compute" \
      description="Sidecar container with libraries for nova-compute." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY vrouter-port-control *.sh /

RUN rpm -Uvh --nodeps $(repoquery -q --location contrail-vrouter-agent) && \
    rpm -Uvh --nodeps $(repoquery -q --location contrail-nova-vif) && \
    mkdir -p /opt/contrail/bin /opt/contrail/site-packages && \
    mv /vrouter-port-control /opt/contrail/bin/vrouter-port-control && \
    chmod a+x /opt/contrail/bin/vrouter-port-control && \
    cp /usr/bin/vrouter-port-control /opt/contrail/bin/vrouter-port-control.py && \
    cp -rf /usr/lib/python3.6/site-packages/vif_plug_vrouter* /opt/contrail/site-packages && \
    cp -rf /usr/lib/python3.6/site-packages/vif_plug_contrail_vrouter* /opt/contrail/site-packages && \
    cp -rf /usr/lib/python3.6/site-packages/nova_contrail_vif* /opt/contrail/site-packages && \
    yum autoremove -y contrail-vrouter-agent contrail-nova-vif && \
    yum clean all -y && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
