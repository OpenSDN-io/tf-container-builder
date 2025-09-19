ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}

ARG CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail general base image" \
      description="The image contains debug symbols for build and may be used to debug Contrail processes." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/contrail/buildroot/manifest.xml /manifest.xml
# TODO: debug packages are unavailable in CI jobs, ignore errors
RUN set -e ; \
    yum install -y contrail-debuginfo || true && \
    yum install -y contrail-vrouter-dpdk-debuginfo || true && \
    yum clean all -y && \
    rm -rf /var/cache/yum

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "
