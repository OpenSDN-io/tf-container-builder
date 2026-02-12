ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Container with code of contrail-status tool" \
      description="Display a list of all components of a Contrail server node and report their current status of active or inactive." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

RUN set -e ; \
    dnf install -y podman lsof ; \
    dnf clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "nodemgr==0.1.dev0" ; \
    rm -rf /root/.cache

COPY contrail-status.py /root
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "
