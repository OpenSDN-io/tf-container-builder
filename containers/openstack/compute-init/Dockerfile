ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Init container for OpenStack Compute" \
      description="Sidecar container with libraries for nova-compute." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY --from=build /root/contrail/buildroot/usr/bin/vrouter-port-control.py /opt/contrail/bin/
COPY vrouter-port-control /opt/contrail/bin/
COPY *.sh /

# don't install deps to minimize footprint
# at deploy step all files will be copied into parent contnaier
# which has all those packages
RUN set -e ; \
    python3 -m pip install --no-deps -t /opt/contrail/site-packages --no-compile --extra-index-url $PIP_REPOSITORY \
        "nova_contrail_vif==0.1.dev0" "contrail-vrouter-api==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
