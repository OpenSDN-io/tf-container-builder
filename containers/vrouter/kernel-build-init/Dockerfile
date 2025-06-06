ARG UBUNTU_DISTR=ubuntu
ARG UBUNTU_DISTR_VERSION=24.04
FROM $UBUNTU_DISTR:$UBUNTU_DISTR_VERSION

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
      summary="Contrail vrouter kernel module for ubuntu" \
      description="This image is used to build vrouter.ko for current ubuntu operating system that it's running on." \
      $VENDOR_DOMAIN".container.name"=$CONTAINER_NAME

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY __licensing.txt /licenses/licensing.txt

# This image is used to build vrouter.ko for current ubuntu OS that it's running on.
# This container uses rpm packages to obtain source of vrouter kernel driver.
# The container needs /usr/src and /lib/modules mounted from the host to build driver.
# And we need to move out /usr/src all that packages can install there.

# this copy should be before yum install
COPY *.repo /etc/yum.repos.d/
# user can put sources.list here which is mirrors definition
# to let copy all files we have to create empty fake.list
COPY *.list /etc/apt/

#TODO: need to get rid of apt-get update
# tpc repo is not to be used as it os dependend
RUN set -e ; \
    rm -f /etc/yum.repos.d/tpc.repo && \
    mkdir -p /opt/contrail/src /contrail_tools /vrouter_src && \
    contrail_version=${CONTRAIL_VERSION:-$CONTRAIL_CONTAINER_TAG} && \
    echo "${contrail_version}" > /contrail_version && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends dkms libelf-dev g++ gcc-12 && \
    apt-get install -y --no-install-recommends dnf rpm2cpio cpio ca-certificates curl && \
    dnf install -y contrail-vrouter-source && \
    mv /usr/src/* /opt/contrail/src/ && \
    vrouter_path=$(find /opt/contrail/src -type f -name "contrail-vrouter-*.tar.gz") && \
    cd  /vrouter_src && \
    tar -xf "${vrouter_path}" && \
    cd /contrail_tools && \
    (cd /var/cache/dnf; for u in `dnf repoquery contrail-vrouter-utils --location`; do curl -LO "$u"; done) && \
    find /var/cache/dnf -name "contrail-vrouter-utils*.rpm" && \
    rpm2cpio $(find /var/cache/dnf -name "contrail-vrouter-utils*.rpm") | cpio -iuvd && \
    cd .. && \
    dnf clean all -y && \
    rm -rf /var/cache/dnf && \
    apt-get purge -y dnf rpm2cpio cpio ca-certificates && \
    apt-get autoremove -y

COPY dkms.conf /opt/contrail/src/
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
