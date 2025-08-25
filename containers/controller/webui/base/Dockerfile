ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}

ARG LINUX_DISTR=centos
ENV NODE_TYPE=webui
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

RUN set -e ; \
    source /etc/os-release && \
    ver=$(echo $VERSION_ID | cut -d '.' -f 1) ; \
    if [[ ${ver} == 9 ]]; then \
        NODEJS_VERSION="0.10.48" ; \
        yum install -y nodejs-${NODEJS_VERSION} ; \
        yum install -y npm-1:8.19.4 ; \
        npm install -g coffeescript livescript ; \
    else \
        NODEJS_VERSION="0.10.48" ; \
        yum module disable -y nodejs || true; \
        yum install -y nodejs-${NODEJS_VERSION} ; \
    fi && \
    yum install -y contrail-web-controller contrail-web-core ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    chown -R $CONTRAIL_USER:$CONTRAIL_USER /usr/src/contrail

COPY custom-images/logo.png /opt/contrail/images/logo.png
COPY custom-images/favicon.ico /opt/contrail/images/favicon.ico
COPY *.sh /
RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done'

CMD ["/usr/bin/tail","-f","/dev/null"]
