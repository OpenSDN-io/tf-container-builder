# This is the general base for all: non-contrail specfic like external and for contrail specific

ARG LINUX_DISTR=rockylinux
ARG LINUX_DISTR_VER=9.3
FROM $LINUX_DISTR:$LINUX_DISTR_VER
# Redefine ARG after FROM (to make them available in the rest of the Dockerfile)
ARG LINUX_DISTR=centos

ARG SITE_MIRROR
ARG VENDOR_NAME
ARG VENDOR_DOMAIN
ARG CONTRAIL_CONTAINER_TAG

LABEL vendor=$VENDOR_NAME \
      version=$CONTRAIL_CONTAINER_TAG \
      release="5.1.0"

# Add required license as text file in Liceses directory
RUN mkdir /licenses
COPY licensing.txt /licenses

ARG LC_ALL="en_US.UTF-8"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"

# These definitions are just for build purposes and must not be changed at runtime
# CONTRAIL_VERSION - used by contrail-version tool
# LANG, LC_ALL - used by some tools, like rabbitmqctl
ENV VENDOR_DOMAIN=$VENDOR_DOMAIN \
    VENDOR_NAME=$VENDOR_NAME \
    CONTRAIL_GID=1999 \
    CONTRAIL_UID=1999 \
    CONTRAIL_USER=contrail \
    CONTRAIL_VERSION=$CONTRAIL_CONTAINER_TAG \
    LC_ALL=$LC_ALL \
    LANG=$LANG \
    LANGUAGE=$LANGUAGE

# this copy should be before yum install
COPY *.repo /etc/yum.repos.d/
COPY pip.conf /etc/
COPY *.sh /

# add epel if it's not added with repo templates
RUN set -ex ; \
    if ! dnf info git-review ; then \
      dnf -y install epel-release ; \
    fi

# remove all not-this-OS repos
RUN set -ex ; \
    source /etc/os-release ; \
    find /etc/yum.repos.d/ | grep -i centos | xargs -r rm ; ls -l /etc/yum.repos.d/ ; \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical ; \
    yum install -y hostname iproute less wget openssl glibc-langpack-en rsync procps-ng python3-pip ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    groupadd --gid $CONTRAIL_GID --system $CONTRAIL_USER ; \
    useradd -md /home/contrail --uid $CONTRAIL_UID --shell /sbin/nologin --system --gid $CONTRAIL_GID $CONTRAIL_USER

CMD ["/usr/bin/tail","-f","/dev/null"]
