#!/bin/bash

enable_kernel_module () {
  local s_dir="$1"
  local d_dir="$2"
  echo "Load vrouter.ko $s_dir for kernel $d_dir"
  mkdir -p /lib/modules/$d_dir/kernel/net/vrouter
  cp -f /opt/contrail/vrouter-kernel-modules/$s_dir/vrouter.ko /lib/modules/$d_dir/kernel/net/vrouter/
  depmod -a $d_dir
}

get_vrouter_dirs () {
  local path=$1
  find "$path" -type f -name "vrouter.ko"
}

get_lists_modules_versions () {
  local list_dirs=$1
  echo "$list_dirs" | awk -F "/" '{print($(NF-1))}' | sed 's/\.el/ el/' | sort -V | sed 's/ /./1'
}

# Install vrouter.ko for a single kernel version.
# Finds the best matching module from available_modules for the given kernel.
install_kernel_module () {
  local modules=$1
  local kver=$2
  local kernel_prefix_regex

  if [ -z "$modules" ]; then
    echo "ERROR: no vrouter.ko modules found"
    return 1
  fi

  # Exact match
  if echo "$modules" | grep -q "$kver" ; then
    enable_kernel_module "$kver" "$kver"
    return 0
  fi

  # Find closest version by minor release prefix (e.g. 5.14.0)
  kernel_prefix_regex="^$(echo $kver | cut -d. -f1,2,3)"
  if ! echo "$modules" | grep -q $kernel_prefix_regex ; then
    kernel_prefix_regex="^$(echo $kver | cut -d. -f1,2)"
  fi

  local sorted_list
  sorted_list=$(echo -e "${modules}\n${kver}" | grep $kernel_prefix_regex | sed 's/\.el/ el/' | sort -V | sed 's/ /./1')

  local best_match
  best_match=$(echo "$sorted_list" | grep -B1 -A1 "$kver" | grep -v "$kver" | head -1)
  if [ -z "$best_match" ]; then
    best_match=$(echo "$modules" | grep $kernel_prefix_regex | head -1)
  fi

  if [ -z "$best_match" ]; then
    echo "ERROR: no compatible vrouter.ko found for kernel $kver"
    return 1
  fi

  enable_kernel_module "$best_match" "$kver"
}
