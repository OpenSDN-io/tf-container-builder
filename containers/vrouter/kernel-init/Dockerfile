ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM rockylinux:9.3

ARG VENDOR_NAME
ARG VENDOR_DOMAIN
ARG CONTRAIL_VERSION
ARG CONTRAIL_CONTAINER_TAG
ARG CONTAINER_NAME

ENV VENDOR_DOMAIN=$VENDOR_DOMAIN \
    VENDOR_NAME=$VENDOR_NAME \
    CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG \
    CONTAINER_NAME=$CONTAINER_NAME

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Kernel init container for vrouter" \
      description="This image is used to build vrouter.ko for current operating system that it's running on." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.repo /etc/yum.repos.d/
COPY *.sh /

# remove all centos repos - they may be a cause of failure in rocky9 dnf cmd
# retry dnf makecache - some repo in upstream has broken metadata
RUN set -e ; \
    mkdir -p /opt/contrail ; \
    for item in `ls /__*` ; do mv $item /${item:3} ; done ; \
    dnf clean all -y ; dnf makecache || dnf makecache || dnf makecache ; \
    find /etc/yum.repos.d/ | grep -i centos | xargs rm ; ls -l /etc/yum.repos.d/ ; \
    dnf install -y wget make gcc gcc-c++ contrail-vrouter-source ; \
    mkdir -p /opt/contrail/src /vrouter_src ; \
    contrail_version=${CONTRAIL_VERSION:-$CONTRAIL_CONTAINER_TAG} ; \
    echo "${contrail_version}" > /contrail_version ; \
    mv /usr/src/* /opt/contrail/src/ ; \
    vrouter_path=$(find /opt/contrail/src -type f -name "contrail-vrouter-*.tar.gz") ; \
    cd  /vrouter_src ; \
    tar -xf "${vrouter_path}" ; \
    /build-kernels.sh ; \
    dnf clean all -y

ENTRYPOINT ["/entrypoint.sh"]