#!/bin/bash -e

source /functions.sh
if [ ! -f "/contrail_version" ] ; then
  echo "ERROR: There is no version specified in /contrail_version file. Exiting..."
  exit 1
fi
contrail_version="$(cat /contrail_version)"
echo "INFO: use vrouter version $contrail_version"

vrouter_dir="/usr/src/vrouter-${contrail_version}"
mkdir -p $vrouter_dir
cp -ap /vrouter_src/. ${vrouter_dir}/
chmod -R 755  ${vrouter_dir}
rm -rf /vrouter_src

mkdir -p /vrouter/${contrail_version}/build/include/
mkdir -p /vrouter/${contrail_version}/build/dp-core
cd /usr/src/vrouter-"${contrail_version}"
./utils/dkms/gen_build_info.sh "${contrail_version}" /vrouter/"${contrail_version}"/build

# otherwise fail with fatal error: stdarg.h: No such file or directory
sed -i 's*#include <stdarg.h>*//#include <stdarg.h>*g' /$vrouter_dir/dp-core/vr_index_table.c

function build_kernel() {
  local kernels_list="$1"
  local original_site=$2
  local kver=$3
  local kernels=""
  local kernel
  for kernel in $kernels_list ; do
    local kernel_name=$(echo $kernel | awk -F'/' '{print $NF}' )
    download_package $original_site $kernel /tmp/$kernel_name --no-check-certificate
    kernels+="/tmp/$kernel_name "
  done
  dnf install -y $kernels
  echo "INFO: run builds for kernel $kver"
  mkdir -p /opt/contrail/vrouter-kernel-modules/$kver/
  make -d -C . KERNELDIR=/lib/modules/$kver/build
  echo "INFO: kernel $kver is ready"
  mv vrouter.* /opt/contrail/vrouter-kernel-modules/$kver/
  rm -f $kernels
  echo "INFO: kernel $kver moved to final place"
}

# rocky9 kernel for 9.0
#kernels="
#  vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-70.30.1.el9_0.x86_64.rpm
#  vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-70.30.1.el9_0.x86_64.rpm
#  vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-70.30.1.el9_0.x86_64.rpm
#  vault/rocky/9.0/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-70.30.1.el9_0.x86_64.rpm
#"
#build_kernel "$kernels" https://dl.rockylinux.org "5.14.0-70.30.1.el9_0.x86_64" &

# rocky9 kernel for 9.1
#kernels="
#  vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-162.23.1.el9_1.x86_64.rpm
#  vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-162.23.1.el9_1.x86_64.rpm
#  vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-162.23.1.el9_1.x86_64.rpm
#  vault/rocky/9.1/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-162.23.1.el9_1.x86_64.rpm
#"
#build_kernel "$kernels" https://dl.rockylinux.org "5.14.0-162.23.1.el9_1.x86_64" &

# TODO: build 9.2, 9.3, 9.4
# rocky9 kernel for 9.2
kernels="
  vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-284.30.1.el9_2.x86_64.rpm
  vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-284.30.1.el9_2.x86_64.rpm
  vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-284.30.1.el9_2.x86_64.rpm
  vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-modules-core-5.14.0-284.30.1.el9_2.x86_64.rpm
  vault/rocky/9.2/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-284.30.1.el9_2.x86_64.rpm
"
build_kernel "$kernels" https://dl.rockylinux.org "5.14.0-284.30.1.el9_2.x86_64"

# rocky9 kernel for 9.3
# TODO: maybe use images from https://dl.rockylinux.org/vault/rocky or https://download.rockylinux.org/pub/rocky
kernels="
  vault/rocky/9.3/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-362.13.1.el9_3.x86_64.rpm
  vault/rocky/9.3/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-362.13.1.el9_3.x86_64.rpm
  vault/rocky/9.3/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-362.13.1.el9_3.x86_64.rpm
  vault/rocky/9.3/BaseOS/x86_64/os/Packages/k/kernel-modules-core-5.14.0-362.13.1.el9_3.x86_64.rpm
  vault/rocky/9.3/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-362.13.1.el9_3.x86_64.rpm
"
build_kernel "$kernels" https://dl.rockylinux.org "5.14.0-362.13.1.el9_3.x86_64"


# rocky9 kernel for 9.5
# TODO: maybe use images from https://dl.rockylinux.org/vault/rocky or https://download.rockylinux.org/pub/rocky
kernels="
  vault/rocky/9.5/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-503.14.1.el9_5.x86_64.rpm
  vault/rocky/9.5/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-503.14.1.el9_5.x86_64.rpm
  vault/rocky/9.5/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-503.14.1.el9_5.x86_64.rpm
  vault/rocky/9.5/BaseOS/x86_64/os/Packages/k/kernel-modules-core-5.14.0-503.14.1.el9_5.x86_64.rpm
  vault/rocky/9.5/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-503.14.1.el9_5.x86_64.rpm
"
build_kernel "$kernels" https://dl.rockylinux.org "5.14.0-503.14.1.el9_5.x86_64"


find /opt/contrail/vrouter-kernel-modules/ | grep vrouter

for k in "5.14.0-284.30.1.el9_2.x86_64" "5.14.0-362.13.1.el9_3.x86_64" ; do
  if [ ! -f /opt/contrail/vrouter-kernel-modules/$k/vrouter.ko ]; then
    echo "ERROR: there is no built module for kernerl $k"
    exit 1
  fi
done
