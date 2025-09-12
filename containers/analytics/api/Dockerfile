ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-analytics-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV SERVICE_NAME=api \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Analytics API" \
      description="Contrail Analytics API provides REST API to access collected analytics data." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY entrypoint.sh /

# contrail-analytics-api/* -> contrail-analytics-api/*
COPY --from=build /root/contrail/build/usr/share/doc/contrail-analytics-api /usr/share/doc/contrail-analytics-api
# html/* -> html/*
COPY --from=build /root/contrail/build/usr/share/doc/contrail-docs /usr/share/doc/contrail-docs
# additional files from sandesh generation
COPY --from=build /root/contrail/build/opt/python/opserver /usr/local/lib/python3.9/site-packages/opserver
RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "opserver==0.1.dev0" ; \
    rm -rf /root/.cache

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/contrail-analytics-api", "-c", "/etc/contrail/contrail-analytics-api.conf", "-c", "/etc/contrail/contrail-keystone-auth.conf"]
