ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-controller-config-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV SERVICE_NAME=device-manager \
    CONTAINER_NAME=$CONTAINER_NAME \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 

LABEL name=$CONTAINER_NAME \
      summary="Contrail Device Manager" \
      description="Contrail Device Manager is used to manage network devices in the Contrail system." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

ARG BUILD_ROOT
# pin cryptography - newer version requires rust compiler just for install.
# but we don't want to install this useless component
COPY --from=build ${BUILD_ROOT}/opt/fabric_ansible_playbooks-0.1.dev0.tar.gz /opt/

RUN set -e ; \
    yum install -y libffi-devel iputils ; \
    # ansible-core requires importlib-resources to be installed
    python3 -m pip install "cryptography<3.5" "importlib-resources<5.1"; \
    python3 -m pip install --no-compile --no-binary :all: ansible ansible-core ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    source /functions.sh ; \
    download_package https://github.com Juniper/ansible-junos-stdlib/archive/2.4.2.tar.gz Juniper.junos ; \
    ansible-galaxy install Juniper.junos ; \
    rm -f Juniper.junos ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "device_manager==0.1.dev0" "fabric_ansible==0.1.dev0" ; \
    rm -rf /root/.cache ; \
    # unpack fabric-ansible
    mkdir -p /etc/ansible ; \
    last="fabric_ansible_playbooks-0.1.dev0.tar.gz" ; \
    echo "DBG: /opt/ last tar.gz = $last" ; \
    tar -xzf /opt/$last -C /opt ; \
    mv /opt/${last//\.tar\.gz/}/* /opt/ ; \
    rmdir /opt/${last//\.tar\.gz/}/ ; \
    cp /opt/ansible.cfg /etc/ansible/ansible.cfg

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/contrail-device-manager", "--conf_file", "/etc/contrail/contrail-device-manager.conf", "--conf_file", "/etc/contrail/contrail-keystone-auth.conf"]
