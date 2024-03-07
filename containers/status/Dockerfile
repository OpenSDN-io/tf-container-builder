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
    source /functions.sh && \
    yum install -y podman contrail-nodemgr && \
    yum install -y python3-devel gcc-c++ && \
    yum clean all -y && \
    rm -rf /var/cache/yum && \
    python3 -m pip install --no-compile --no-binary=protobuf "docker==2.4.2" "grpcio==1.29.0" "protobuf==3.17.3" "containerd==1.5.2" "lxml==4.0.0" "netaddr==0.10.1" "greenlet==1.0.0" "gevent==1.4.0" "bottle" "fysom" "future" "six" "PyYAML>=5.1" "psutil"

COPY contrail-status.py /root
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "
