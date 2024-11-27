ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-controller-config-base:${CONTRAIL_CONTAINER_TAG}

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

# git rpm cannot be remove as it removes contrail-utils, and common by deps
# use direct download to be able to download from cache instead of `ansible-galaxy install Juniper.junos,2.4.2`

# Fix ASCII codec error by setting locale to UTF-8
RUN yum install -y libffi-devel && \
    python3 -m pip install --no-compile --no-binary :all: ansible ansible-core && \
    yum install -y git iputils && \
    yum clean all -y && \
    rm -rf /var/cache/yum && \
    source /functions.sh && \
    download_package https://github.com Juniper/ansible-junos-stdlib/archive/2.4.2.tar.gz Juniper.junos && \
    ansible-galaxy install Juniper.junos && \
    rm -f Juniper.junos

COPY *.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/contrail-device-manager", "--conf_file", "/etc/contrail/contrail-device-manager.conf", "--conf_file", "/etc/contrail/contrail-keystone-auth.conf"]
