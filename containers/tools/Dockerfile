ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-base:${CONTRAIL_CONTAINER_TAG}

ARG SITE_MIRROR
ARG CONTAINER_NAME
ENV CONTAINER_NAME=$CONTAINER_NAME
LABEL name=$CONTAINER_NAME \
      summary="A common tool for debugging" \
      description="The image contains scripts to debug Contrail processes." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# tshark is needed for sandump tool which is included into contrail-tools package
RUN set -e ; \
      source /etc/os-release ; \
      yum install -y sudo openssh-clients bzip2 contrail-tools contrail-vrouter-dpdk-tools ; \
      yum clean all -y ; \
      rm -rf /var/cache/yum ; \
      source /functions.sh ; \
      ln -s /usr/bin/tshark /usr/sbin/tshark3_2

ENV PS1="\033[1m($CONTAINER_NAME)\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "

ENTRYPOINT ["/bin/bash"]
