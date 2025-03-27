ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV SERVICE_NAME=nodemgr \
    CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="Contrail Node Manager" \
      description="Contrail Node Manager is a monitor process per contrail virtual node that tracks the running state of the processes." \
      $VENDOR_DOMAIN".service"=$SERVICE_NAME \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# for building from rpms
# install chrony, ntp and iputils-clockdiff to enable checking time sync by nodemgr
RUN yum install -y autogen-libopts.x86_64 chrony podman 2>&1 | tee /tmp/log ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "nodemgr==0.1.dev0" ; \
    rm -rf /root/.cache

COPY *.sh /
ENTRYPOINT ["/entrypoint.sh"]
# use shell form for CMD as shell variables processing is required here
CMD /usr/local/bin/contrail-nodemgr --nodetype=${NODEMGR_TYPE}
