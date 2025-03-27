ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
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

RUN set -e ; \
    yum install -y dhclient contrail-vrouter-agent haproxy libvirt-client ; \
    rpm -qi contrail-vrouter-agent | awk '/Version/{print($3)}' > /contrail_build_version ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    ldconfig ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail-vrouter-api==0.1.dev0" "opencontrail-vrouter-netns==0.1.dev0" ; \
    rm -rf /root/.cache

COPY *.sh /
# /etc/dhcp/dhclient-script is allowed by apparmor to execute
COPY vhost0-dhcp/dhclient-script /etc/dhcp/dhclient-script
COPY vhost0-dhcp/vhost0-nameservers.sh /etc/dhcp/dhclient-exit-hooks.d/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-vrouter-agent"]
