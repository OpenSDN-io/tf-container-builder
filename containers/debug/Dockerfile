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

ARG BUILD_ROOT
ARG DEBUGINFO_ROOT
COPY --from=build ${BUILD_ROOT}/manifest.xml /manifest.xml
COPY --from=build ${DEBUGINFO_ROOT} ${DEBUGINFO_ROOT}

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "
