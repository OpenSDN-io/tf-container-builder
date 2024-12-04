ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM centos:7

ARG VENDOR_NAME
ARG VENDOR_DOMAIN
ARG CONTRAIL_VERSION
ARG CONTRAIL_CONTAINER_TAG
ARG CONTAINER_NAME

ENV VENDOR_DOMAIN=$VENDOR_DOMAIN \
    VENDOR_NAME=$VENDOR_NAME \
    CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG \
    CONTAINER_NAME=$CONTAINER_NAME

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0" \
      name=$CONTAINER_NAME \
      summary="Kernel init container for vrouter" \
      description="This image is used to build vrouter.ko for current operating system that it's running on." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

COPY *.repo /etc/yum.repos.d/
COPY *.sh /

RUN set -e ; \
    mkdir -p /opt/contrail ; \
    for item in `ls /__*` ; do mv $item /${item:3} ; done ; \
    sed -i 's/mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/CentOS-* ; \
    sed -Ei 's|^#([[:blank:]]*baseurl=http://mirror.centos.org)|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* ; \
    yum clean all -y ; yum makecache ; \
    find /etc/yum.repos.d/ | grep -i rocky | xargs -r rm ; ls -l /etc/yum.repos.d/ ; \
    rpm -Uvh --nodeps $(repoquery -q --location contrail-vrouter) ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]