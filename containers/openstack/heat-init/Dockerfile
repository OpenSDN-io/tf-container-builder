ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Init container for OpenStack Heat" \
      description="Sidecar container with libraries for heat services." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.sh /

# don't install deps to minimize footprint
# at deploy step all files will be copied into parent contnaier
# which has all those packages
RUN \
    mkdir -p /opt/contrail/site-packages && \
    python3 -m pip install --no-deps -t /opt/contrail/site-packages --no-compile --extra-index-url $PIP_REPOSITORY \
        "contrail_api_client==0.1.dev0" "contrail_heat==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
