#!/bin/bash

source /common.sh

if [[ ! -d /host/usr/bin ]]; then
  echo "ERROR: there is no mount /host/usr/bin from Host's /usr/bin. Utility contrail-status could not be created."
  exit 1
fi

if [[ -z "$CONTRAIL_STATUS_IMAGE" ]]; then
  echo 'ERROR: variable $CONTRAIL_STATUS_IMAGE is not defined. Utility contrail-status could not be created.'
  exit 1
fi

vol_opts=''
env_opts="--env INTROSPECT_SSL_ENABLE=$INTROSPECT_SSL_ENABLE"
cmd_args=''
# ssl folder is always to mounted: in case of IPA init container
# should not generate cert and is_ssl_enabled is false for this container,
# certs&keys are generated by IPA
vol_opts+=' -v /etc/hosts:/etc/hosts:ro'
vol_opts+=' -v /etc/localtime:/etc/localtime:ro'
vol_opts+=' -v /var/run:/var/run'
vol_opts+=' -v /var/lib/containers:/var/lib/containers'
if [[ -e /etc/contrail/ssl ]] ; then
  vol_opts+=' -v /etc/contrail/ssl:/etc/contrail/ssl:ro'
fi
if [[ -n "${SERVER_CA_CERTFILE}" ]] && [[ -e ${SERVER_CA_CERTFILE} ]] ; then
  # In case of FreeIPA CA file is palced in /etc/ipa/ca.crt
  # and should be mounted additionally
  if [[ ! "${SERVER_CA_CERTFILE}" =~ "/etc/contrail/ssl" ]] ; then
    vol_opts+=" -v ${SERVER_CA_CERTFILE}:${SERVER_CA_CERTFILE}:ro"
    cmd_args+="--cacert ${SERVER_CA_CERTFILE}"
  fi
fi

# cause multiple instances can generate this at one moment - this operation should be atomic
# TODO: it is expected that ssl dirs are byt default, it is needed to detect dirs and
# do mount volumes appropriately

tmp_argv="/root/contrail-status.py ${cmd_args} \$@"
tmp_suffix="--rm --pid host --net host --privileged ${CONTRAIL_STATUS_IMAGE} ${tmp_argv}"
tmp_file=/host/usr/bin/contrail-status.tmp.${RANDOM}
cat > $tmp_file << EOM
#!/bin/bash
u=\$(which docker 2>/dev/null)
if pidof dockerd >/dev/null 2>&1 || pidof dockerd-current >/dev/null 2>&1 ; then
    \$u run $vol_opts $env_opts $tmp_suffix
    exit \$?
fi
u=\$(which podman 2>/dev/null)
if ((\$? == 0)); then
    r="\$u run $vol_opts $env_opts "
    r+=' --volume=/run/runc:/run/runc'
    r+=' --volume=/sys/fs:/sys/fs'
    r+=' --cap-add=ALL --security-opt seccomp=unconfined'
    \$r $tmp_suffix
    exit \$?
fi
u=\$(which ctr 2>/dev/null)
if ((\$? == 0)); then
    r="\$u --namespace k8s.io run --rm --privileged"
    r+=' --mount type=bind,src=/etc/localtime,dst=/etc/localtime,options=rbind:ro'
    r+=' --mount type=bind,src=/etc/hosts,dst=/etc/hosts,options=rbind:ro'
    r+=' --mount type=bind,src=/run/containerd,dst=/run/containerd,options=rbind:rw'
    r+=' --mount type=bind,src=/sys/fs/cgroup,dst=/sys/fs/cgroup,options=rbind:rw'
    \$r ${CONTRAIL_STATUS_IMAGE} \$RANDOM ${tmp_argv}
    exit \$?
fi
EOM

echo "INFO: generated contrail-status"
cat $tmp_file

chmod 755 $tmp_file
mv -f $tmp_file /host/usr/bin/contrail-status
