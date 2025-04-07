ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
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

RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "opserver==0.1.dev0" ; \
    rm -rf /root/.cache ; \
    yum install -y contrail-docs ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/contrail-analytics-api", "-c", "/etc/contrail/contrail-analytics-api.conf", "-c", "/etc/contrail/contrail-keystone-auth.conf"]
