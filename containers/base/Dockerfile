# This is the base for contrail specific children

ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/contrail-general-base:${CONTRAIL_CONTAINER_TAG}
ARG BASE_EXTRA_RPMS=""

# note: ldconfig looks strange. contrail-lib installs shared libraries but do not call it...
# note: we decide to install python3 packages by pip because they are absent in RHEL7/CentOS7 repos.
# these two packages (six, future) are installed here because they are needed for contrail-utils at least.
# further all deps should be moved to modules itself and here we must use requirements.txt to install deps.
# and one more next step is to install python modules from sources without creating RPM.
# WARNING! all pip deps must be installed with pinned version to avoid breakages when pypi is upgraded.
RUN \
    BASE_EXTRA_RPMS=$(echo $BASE_EXTRA_RPMS | tr -d '"' | tr ',' ' ') ; \
    if [[ -n "$BASE_EXTRA_RPMS" ]] ; then \
        echo "INFO: contrail-base: install $BASE_EXTRA_RPMS" ; \
        yum install -y $BASE_EXTRA_RPMS ; \
        echo "INFO: importing gpg keys from any newly installed repos" ; \
        [ -d /etc/pki/rpm-gpg ] && rpm --import /etc/pki/rpm-gpg/* ; \
    fi ; \
    yum install -y nc gcc-c++ gcc python3-devel ; \
    yum install -y contrail-lib contrail-setup contrail-utils python3-contrail 2>&1 | tee /tmp/log ; \
    grep -i "error:" /tmp/log && exit 1 ; \
    # for debug purposes
    python3 -m pip install --no-compile remote-pdb ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    ldconfig

COPY *.sh /

ENV PS1="\033[1m($(printenv NODE_TYPE)-$(printenv SERVICE_NAME))\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "

CMD ["/usr/bin/tail","-f","/dev/null"]
