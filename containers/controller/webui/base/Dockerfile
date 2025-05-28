ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}

ARG LINUX_DISTR=centos
ARG BASE_EXTRA_RPMS=""
ENV NODE_TYPE=webui
LABEL $VENDOR_DOMAIN".pod"=$NODE_TYPE

RUN set -e ; \
    BASE_EXTRA_RPMS=$(echo $BASE_EXTRA_RPMS | tr -d '"' | tr ',' ' ') ; \
    if [[ -n "$BASE_EXTRA_RPMS" ]] ; then \
        echo "INFO: contrail-base: install $BASE_EXTRA_RPMS" ; \
        yum install -y $BASE_EXTRA_RPMS ; \
        echo "INFO: importing gpg keys from any newly installed repos" ; \
        [ -d /etc/pki/rpm-gpg ] && rpm --import /etc/pki/rpm-gpg/* ; \
        if [[ "$LINUX_DISTR" == "centos" ]]; then \
            for file in /etc/yum.repos.d/rdo-* ; do grep -v mirrorlist= "$file" > "$file".new && mv "$file".new "$file" ; done ; \
            sed -i 's|#\s*baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/rdo-* ; \
        fi ; \
    fi ; \
    yum module disable -y nodejs || true; \
    yum install -y nodejs-0.10.48 contrail-web-controller contrail-web-core ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    chown -R $CONTRAIL_USER:$CONTRAIL_USER /usr/src/contrail

COPY custom-images/logo.png /opt/contrail/images/logo.png
COPY custom-images/favicon.ico /opt/contrail/images/favicon.ico
COPY *.sh /
RUN /bin/bash -c 'for item in `ls /__*` ; do mv $item /${item:3} ; done'

CMD ["/usr/bin/tail","-f","/dev/null"]
