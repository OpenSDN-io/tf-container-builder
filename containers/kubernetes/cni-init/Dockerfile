ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Kubernetes Container Network Interface" \
      description="Contrail provides support for Container Network Interface for Kubernetes." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/contrail/build/usr/bin/contrail-k8s-cni /usr/bin/contrail-k8s-cni
RUN set -e ; \
    source /functions.sh ; \
    download_package https://github.com containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz /opt/cni-v0.3.0.tgz

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

