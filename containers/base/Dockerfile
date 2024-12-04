# This is the base for contrail specific children

ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}
ARG BASE_EXTRA_RPMS=""
ARG PIP_REPOSITORY
ARG LINUX_DISTR=centos

# note: ldconfig looks strange. contrail-lib installs shared libraries but do not call it...
# WARNING! all pip deps must be installed with pinned version to avoid breakages when pypi is upgraded.
# BASE_EXTRA_RPMS by default has link to openstack repo with old centos which must be patched also
RUN set -e ; \
    sed -e '/^tsflags=nodocs/d' -i /etc/yum.conf ; \
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
    # net-tools has netstat which is used by opensdn-test inside kubemanager container
    yum install -y nc gcc python3-devel contrail-lib net-tools ; \
    # NOTE: utils must be placed into /opt/contrail/utils
    # TODO: rework utils with extra_scripts in setup.py
    python3 -m pip install --no-compile --extra-index-url $PIP_REPOSITORY "contrail_config_utils==0.1.dev0" ; \
    mkdir -p /opt/contrail/utils ; \
    pkg_path=$(find /usr/local/lib -name contrail_config_utils) ; \
    ls -l $pkg_path ; \
    cp $pkg_path/* /opt/contrail/utils/ ; \
    chmod a+x /opt/contrail/utils/* ; \
    rm -rf /tmp/utils ; \
    # for debug purposes
    python3 -m pip install --no-compile remote-pdb ; \
    rm -rf /root/.cache ; \
    yum clean all -y ; \
    rm -rf /var/cache/yum ; \
    ldconfig

COPY *.sh /

ENV PS1="\033[1m($(printenv NODE_TYPE)-$(printenv SERVICE_NAME))\033[m\017[$(id -un)@$(hostname -s) $(pwd)]$ "

CMD ["/usr/bin/tail","-f","/dev/null"]
