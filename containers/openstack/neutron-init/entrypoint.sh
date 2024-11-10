#!/bin/bash -ex

echo "INFO: passed OPENSTACK_VERSION is $OPENSTACK_VERSION"
if [[ -z "$OPENSTACK_VERSION" ]]; then
  echo "ERROR: OPENSTACK_VERSION is required to init neutron plugin correctly"
  exit 1
fi

function copy_sources() {
  local src_path=$1
  local module=$2
  for item in `ls -d $src_path/${module}*` ; do
    cp -r $item /opt/plugin/site-packages/
  done
}

mkdir -p /opt/plugin/site-packages

# python3
cp -rf /opt/contrail/site-packages/* /opt/plugin/site-packages/