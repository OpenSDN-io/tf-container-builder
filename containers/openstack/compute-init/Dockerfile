ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Init container for OpenStack Compute" \
      description="Sidecar container with libraries for nova-compute." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY vrouter-port-control *.sh /

# don't install deps to minimize footprint
# at deploy step all files will be copied into parent contnaier
# which has all those packages
# TODO: move vrouter-port-control out of agent package
RUN set -e ; \
    rpm -Uvh --nodeps $(repoquery -q --location contrail-vrouter-agent) ; \
    mkdir -p /opt/contrail/bin /opt/contrail/site-packages ; \
    mv /vrouter-port-control /opt/contrail/bin/vrouter-port-control ; \
    chmod a+x /opt/contrail/bin/vrouter-port-control ; \
    cp /usr/bin/vrouter-port-control /opt/contrail/bin/vrouter-port-control.py ; \
    yum autoremove -y contrail-vrouter-agent contrail-nova-vif ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-deps -t /opt/contrail/site-packages --no-compile --extra-index-url $PIP_REPOSITORY \
        "nova_contrail_vif==0.1.dev0" "contrail-vrouter-api==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
