ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM rockylinux:9.1

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

RUN \
    mkdir -p /opt/contrail && \
    for item in `ls /__*` ; do mv $item /${item:3} ; done && \
    dnf -y update-minimal --security --sec-severity=Important --sec-severity=Critical && \
    pkgs="NetworkManager initscripts ethtool pciutils sudo python3-setuptools " && \
    pkgs+="hostname iproute less wget openssl " && \
    pkgs+="contrail-vrouter-utils contrail-lib " && \
    dnf install -y $pkgs && \
    dnf install -y --enablerepo=devel network-scripts &&\
    cp -r /etc/sysconfig/network-scripts /opt/contrail/ && \
    mkdir -p /opt/contrail/src /vrouter_src && \
    contrail_version=${CONTRAIL_VERSION:-$CONTRAIL_CONTAINER_TAG} && \
    echo "${contrail_version}" > /contrail_version && \
    dnf install -y module-init-tools make gcc gcc-c++ && \
    dnf install -y contrail-vrouter-source contrail-vrouter-utils && \
    mv /usr/src/* /opt/contrail/src/ && \
    vrouter_path=$(find /opt/contrail/src -type f -name "contrail-vrouter-*.tar.gz") && \
    cd  /vrouter_src && \
    tar -xf "${vrouter_path}" && \
    /build-kernels.sh && \
    yum clean all -y && \
    rm -rf /var/cache/yum

ENTRYPOINT ["/entrypoint.sh"]