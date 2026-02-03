#!/bin/bash

# these next folders must be mounted to compile vrouter.ko in ubuntu: /usr/src /lib/modules

# to save output logs to correct place
export SERVICE_NAME=kernel-init

source /common.sh
source /kernel-init-functions.sh

# /usr/src is mounted from host and overwrites image content. Copy vrouter source there at runtime.
contrail_version="$(cat /contrail_version)"
vrouter_src="/opt/vrouter_src/vrouter-${contrail_version}"
vrouter_dest="/usr/src/vrouter-${contrail_version}"
if [ -d "$vrouter_src" ] && [ ! -d "$vrouter_dest" ]; then
  cp -a "$vrouter_src" "$vrouter_dest"
  chmod -R 755 "$vrouter_dest"
fi

if ! /build-kernel.sh ; then
  echo "ERROR: build-kernel.sh failed, cannot proceed"
  exit 1
fi

# copy vif util to host
if [[ -d /host/bin && ! -f /host/bin/vif ]] ; then
  /bin/cp -f /usr/bin/vif /host/bin/vif
  chmod +x /host/bin/vif
fi

# Install the built vrouter.ko for the running kernel
current_kver="$(uname -r)"
list_dirs_modules=$(get_vrouter_dirs "/opt/contrail/.")
available_modules=$(get_lists_modules_versions "$list_dirs_modules")
echo "Available vrouter.ko versions:"
echo "$available_modules"

install_kernel_module "$available_modules" "$current_kver"

exec $@
