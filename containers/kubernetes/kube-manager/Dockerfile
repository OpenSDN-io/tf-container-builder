ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV NODE_TYPE=kubernetes \
    SERVICE_NAME=kube-manager \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Kubernetes Manager" \
      description="Contrail Kubernetes Manager provides listening to the Kubernetes API messages and creating corresponding resources in the Contrail API database." \
      $VENDOR_DOMAIN".pod"=$NODE_TYPE \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

RUN set -e ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "kube_manager==0.1.dev0"
  
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/contrail-kube-manager", "-c", "/etc/contrail/contrail-kubernetes.conf"]
