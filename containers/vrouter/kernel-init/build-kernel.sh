#!/bin/bash -ex

# Builds vrouter.ko for the running host kernel.
# Requires /lib/modules/<kver>/build to be available (kernel-devel must be
# installed on the host and /lib/modules mounted into the container).

contrail_version="$(cat /contrail_version)"
current_kver="$(uname -r)"
build_kver="${current_kver}"
module_dir="/opt/contrail/vrouter-kernel-modules/${build_kver}"

if [ -f "${module_dir}/vrouter.ko" ]; then
  echo "INFO: vrouter.ko already built for ${current_kver}"
  exit 0
fi

vrouter_dir="/usr/src/vrouter-${contrail_version}"

if [ ! -d "/lib/modules/${build_kver}/build" ]; then
  available_build=$(find /lib/modules -maxdepth 2 -type d -name build 2>/dev/null | head -1)
  if [ -n "$available_build" ]; then
    build_kver=$(dirname "$available_build" | xargs basename)
    module_dir="/opt/contrail/vrouter-kernel-modules/${build_kver}"
    if [ -f "${module_dir}/vrouter.ko" ]; then
      echo "INFO: vrouter.ko already built for ${build_kver}"
      exit 0
    fi
  else
    echo "ERROR: /lib/modules/${build_kver}/build is not available."
    echo "ERROR: kernel-devel must be installed on the host and /lib/modules mounted into the container."
    exit 1
  fi
fi

echo "INFO: Building vrouter.ko for ${build_kver}"
cd "${vrouter_dir}"
mkdir -p "${module_dir}"
make -C . KERNELDIR="/lib/modules/${build_kver}/build"
mv vrouter.* "${module_dir}/"
echo "INFO: vrouter.ko for ${build_kver} is ready"
