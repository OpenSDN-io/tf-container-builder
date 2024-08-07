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
# WARNING! python2-setuptools is to be installed as it here below to get correct version -
#   from the yum repo install via BASE_EXTRA_RPMS. pip2 is to installed BEFORE python3 that installs pip3
#   byt dependencies.
# NOTE! all other deps must be installed in the container that requires such deps.
RUN \
    BASE_EXTRA_RPMS=$(echo $BASE_EXTRA_RPMS | tr -d '"' | tr ',' ' ') && \
    if [[ -n "$BASE_EXTRA_RPMS" ]] ; then \
        echo "INFO: contrail-base: install $BASE_EXTRA_RPMS" ; \
        yum install -y $BASE_EXTRA_RPMS ; \
        echo "INFO: importing gpg keys from any newly installed repos" ; \
        [ -d /etc/pki/rpm-gpg ] && rpm --import /etc/pki/rpm-gpg/* ; \
    fi && \
    python2 -m pip install --no-compile remote-pdb && \
    source /etc/os-release && \
    if [[ "$ID" == 'rhel' && "${PLATFORM_ID//*:/}" == 'el8' ]] ; then \
        python2 -m pip install --no-compile "gevent==1.1.2"  "greenlet<2.0.0" && \
        yum install -y python-kazoo python2-requests ; \
    fi && \
    yum install -y nc gcc-c++ gcc python3-devel contrail-lib contrail-setup contrail-utils python-contrail python3-contrail && \
    python3 -m pip install --no-compile "future==0.18.2" "six==1.13.0" remote-pdb && \
    yum clean all -y && \
    rm -rf /var/cache/yum && \
    ldconfig

COPY *.sh /

ENV PS1="\033[1m($(printenv NODE_TYPE)-$(printenv SERVICE_NAME))\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "

CMD ["/usr/bin/tail","-f","/dev/null"]
