ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}

ARG LINUX_DISTR=centos
ENV NODE_TYPE=webui
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

ARG BUILD_ROOT
# contrail-config/html/* -> contrail-config/html/*
COPY --from=build ${BUILD_ROOT}/usr/src/contrail/contrail-web-controller /usr/src/contrail/contrail-web-controller
COPY --from=build ${BUILD_ROOT}/usr/src/contrail/contrail-web-core /usr/src/contrail/contrail-web-core
RUN set -e ; \
    source /etc/os-release && \
    ver=$(echo $VERSION_ID | cut -d '.' -f 1) ; \
    if [[ ${ver} != 9 ]]; then \
        echo "ERROR: only version 9 of redhat-like OS is supported" ; \
        exit 1 ; \
    fi ; \
    yum install -y redis nodejs-1:16.20.2 npm-1:8.19.4 ; \
    npm install -g coffeescript livescript ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    mkdir /usr/lib64/node_modules ; \
    cp -rp /usr/src/contrail/contrail-web-core/node_modules/* /usr/lib64/node_modules/ ; \
    rm -rf /usr/src/contrail/contrail-web-core/node_modules ; \
    ln -s /usr/lib64/node_modules /usr/src/contrail/contrail-web-controller/node_modules ; \
    ln -s /usr/lib64/node_modules /usr/src/contrail/contrail-web-core/node_modules ; \
    rm -f /usr/src/contrail/contrail-web-core/config/config.global.js ; \
    ln -s /etc/contrail/config.global.js /usr/src/contrail/contrail-web-core/config/config.global.js ; \
    chown -R $CONTRAIL_USER:$CONTRAIL_USER /usr/src/contrail

COPY custom-images/logo.png /opt/contrail/images/logo.png
COPY custom-images/favicon.ico /opt/contrail/images/favicon.ico
COPY *.sh /
RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done'

CMD ["/usr/bin/tail","-f","/dev/null"]
