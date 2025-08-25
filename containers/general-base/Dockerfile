# This is the general base for all: non-contrail specfic like external and for contrail specific

ARG LINUX_DISTR=centos
ARG LINUX_DISTR_VER=7.9.2009
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

# do not upgrade coreutils: https://bugzilla.redhat.com/show_bug.cgi?id=1764152
# remove all not-this-OS repos
RUN set -e ; \
    source /etc/os-release ; \
    if [[ "$LINUX_DISTR" == "centos" ]]; then \
        for file in /etc/yum.repos.d/CentOS-* ; do grep -v mirrorlist= "$file" > "$file".new && mv "$file".new "$file" ; done ; \
        sed -i 's|#\s*baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* ; \
        find /etc/yum.repos.d/ | grep -i rocky | xargs -r rm ; ls -l /etc/yum.repos.d/ ; \
    else \
        find /etc/yum.repos.d/ | grep -i centos | xargs -r rm ; ls -l /etc/yum.repos.d/ ; \
    fi ; \
    yum update -y -x "redhat-release*" -x "coreutils*"  \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical ; \
    yum install -y hostname iproute less wget openssl glibc-langpack-en rsync ; \
    source /functions.sh ; \
    yum install -y python3 python3-pip ; \
    # pip9 is too old and breaks install of gevent with c++ errors
    python3 -m pip install --upgrade pip setuptools ; \
    rm -rf /root/.cache ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    groupadd --gid $CONTRAIL_GID --system $CONTRAIL_USER ; \
    useradd -md /home/contrail --uid $CONTRAIL_UID --shell /sbin/nologin --system --gid $CONTRAIL_GID $CONTRAIL_USER

CMD ["/usr/bin/tail","-f","/dev/null"]
