# This is the base for contrail specific children

ARG BUILD_IMAGE
ARG CONTRAIL_REGISTRY
ARG CONTRAIL_CONTAINER_TAG
FROM ${BUILD_IMAGE} AS build

FROM ${CONTRAIL_REGISTRY}/opensdn-general-base:${CONTRAIL_CONTAINER_TAG}
ARG PIP_REPOSITORY
ARG LINUX_DISTR=centos

ARG BUILD_ROOT
# contrail-lib package - copy libs here to minimize size of several leaf images
# maybe we have to extract one more base image for c++ binaries
COPY --from=build ${BUILD_ROOT}/usr/lib/libipfix.so.1.0 /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/liblog4cplus-2.1.so.9.0.1 /usr/lib/
COPY --from=build ${BUILD_ROOT}/usr/lib/liblog4cplusU-2.1.so.9.0.1 /usr/lib/

# COPY copies content instead of symlink - create symlinks manually
# WARNING! all pip deps must be installed with pinned version to avoid breakages when pypi is upgraded.
RUN set -e ; \
    ln -s /usr/lib/libipfix.so.1.0 /usr/lib/libipfix.so ; \
    ln -s /usr/lib/liblog4cplus-2.1.so.9.0.1 /usr/lib/liblog4cplus-2.1.so ; \
    ln -s /usr/lib/liblog4cplus-2.1.so.9.0.1 /usr/lib/liblog4cplus-2.1.so.9 ; \
    ln -s /usr/lib/liblog4cplusU-2.1.so.9.0.1 /usr/lib/liblog4cplusU-2.1.so ; \
    ln -s /usr/lib/liblog4cplusU-2.1.so.9.0.1 /usr/lib/liblog4cplusU-2.1.so.9 ; \
    sed -e '/^tsflags=nodocs/d' -i /etc/yum.conf ; \
    # net-tools has netstat which is used in vrouter-dpdk, opensdn-status and by opensdn-test inside kubemanager container
    # libatomic libuv userspace-rcu tbb - for c++ binaries
    # crudini - mostly for tf-test repo
    yum install -y nc gcc python3-devel net-tools libatomic libuv userspace-rcu tbb crudini ; \
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
