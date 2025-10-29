ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

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

ARG BUILD_ROOT
COPY --from=build ${BUILD_ROOT}/usr/bin/tools/vif /usr/bin/
COPY --from=build ${BUILD_ROOT}/usr/src/modules/contrail-vrouter.tar.gz /opt/contrail/src/

# remove all centos repos - they are cause of failure in rocky9 dnf cmd
RUN set -e ; \
    for item in `ls /__*` ; do mv $item /${item:3} ; done ; \
    find /etc/yum.repos.d/ | grep -i centos | xargs -r rm ; ls -l /etc/yum.repos.d/ ; \
    dnf clean all -y ; dnf makecache ; \
    dnf install -y wget make gcc gcc-c++ ; \
    dnf clean all -y ; \
    mkdir -p /vrouter_src ; \
    contrail_version=${CONTRAIL_VERSION:-$CONTRAIL_CONTAINER_TAG} ; \
    echo "${contrail_version}" > /contrail_version ; \
    cd /vrouter_src ; \
    tar -xf /opt/contrail/src/contrail-vrouter.tar.gz ; \
    /build-kernels.sh

ENTRYPOINT ["/entrypoint.sh"]