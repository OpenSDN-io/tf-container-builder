ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-base:${CONTRAIL_CONTAINER_TAG}

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Container with code of contrail-status tool" \
      description="Display a list of all components of a Contrail server node and report their current status of active or inactive." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

RUN \
    yum install -y python3-devel gcc-c++ ; \
    yum install -y podman contrail-nodemgr 2>&1 | tee /tmp/log ; \
    grep -i "error:" /tmp/log && exit 1 ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

COPY contrail-status.py /root
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "
