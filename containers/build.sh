#!/bin/bash
# Builds containers. Parses common.env to take CONTRAIL_REGISTRY, CONTRAIL_REPOSITORY, CONTRAIL_CONTAINER_TAG or takes them from
# environment.
# Parameters:
# path: relative path (from this directory) to module(s) for selective build. Example: ./build.sh controller/webui
#   if it's omitted then script will build all
#   "all" as argument means build all. It's needed if you want to build all and pass some docker opts (see below).
#   "list" will list all relative paths for build in right order. It's needed for automation. Example: ./build.sh list | grep -v "^INFO:"
# opts: extra parameters to pass to docker. If you want to pass docker opts you have to specify 'all' as first param (see 'path' argument above)

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"
source "$my_dir/../parse-env.sh"

path="$1"
shift
opts="$@"

function log() {
  echo -e "$(date -u +"%Y-%m-%d %H:%M:%S,%3N"): INFO: $@"
}

function err() {
  echo -e "$(date -u +"%Y-%m-%d %H:%M:%S,%3N"): ERROR: $@" >&2
}
function append_log_file() {
  local logfile=$1
  local always_echo=${2:-'false'}
  local line=''
  while read line ; do
    if [[ "${CONTRAIL_KEEP_LOG_FILES,,}" != 'true' || "$always_echo" != 'false' ]] ; then
      echo "$line" | tee -a $logfile
    else
      echo "$line" >> $logfile
    fi
  done
}

#SITE_MIRROR is an URL to the root of cache. This code will look for the files inside predefined folder
if [[ -n "${SITE_MIRROR}" ]]; then
  export SITE_MIRROR="${SITE_MIRROR}/external-web-cache"
fi

log "Target platform: $LINUX_DISTR:$LINUX_DISTR_VER"
log "External Web Cache: $SITE_MIRROR"
log "Containers name prefix: $CONTAINER_NAME_PREFIX"
log "Contrail container tag: $CONTRAIL_CONTAINER_TAG"
log "Contrail registry: $CONTRAIL_REGISTRY"
log "Contrail repository: $CONTRAIL_REPOSITORY"
log "Parallel build: $CONTRAIL_PARALLEL_BUILD"
log "Keep log files: $CONTRAIL_KEEP_LOG_FILES"
log "Vendor: $VENDOR_NAME"
log "Vendor Domain: $VENDOR_DOMAIN"

if [ -n "$opts" ]; then
  log "Options: $opts"
fi

docker_ver=$(sudo docker -v | awk -F' ' '{print $3}' | sed 's/,//g')
log "Docker version: $docker_ver"

was_errors=0

function process_container() {
  local dir=${1%/}
  local docker_file=$2
  local exit_code=0
  if [[ $op == 'list' ]]; then
    echo "${dir#"./"}"
    return
  fi
  local start_time=$(date +"%s")
  # if variable CUSTOM_CONTAINER_NAME has been set up - use its value as builded container name
  # use CUSTOM_CONTAINER_NAME for build the only src containers
  if [[ -z "${CUSTOM_CONTAINER_NAME}" ]] ; then
    local container_name=`echo ${dir#"./"} | tr "/" "-"`
    local container_name="${CONTAINER_NAME_PREFIX}-${container_name}"
  else
    local container_name=${CUSTOM_CONTAINER_NAME}
  fi

  local tag="${CONTRAIL_CONTAINER_TAG}"

  local logfile='build-'$container_name'.log'
  log "Building $container_name" | append_log_file $logfile true

  local build_arg_opts='--network host'
  build_arg_opts+=" --build-arg PIP_REPOSITORY=${PIP_REPOSITORY}"
  build_arg_opts+=" --build-arg CONTRAIL_REGISTRY=${CONTRAIL_REGISTRY}"
  build_arg_opts+=" --build-arg CONTRAIL_CONTAINER_TAG=${tag}"
  build_arg_opts+=" --build-arg SITE_MIRROR=${SITE_MIRROR}"
  build_arg_opts+=" --build-arg LINUX_DISTR_VER=${LINUX_DISTR_VER}"
  build_arg_opts+=" --build-arg LINUX_DISTR=${LINUX_DISTR}"
  build_arg_opts+=" --build-arg CONTAINER_NAME=${container_name}"
  build_arg_opts+=" --build-arg UBUNTU_DISTR_VERSION=${UBUNTU_DISTR_VERSION}"
  build_arg_opts+=" --build-arg UBUNTU_DISTR=${UBUNTU_DISTR}"
  build_arg_opts+=" --build-arg VENDOR_NAME=${VENDOR_NAME}"
  build_arg_opts+=" --build-arg VENDOR_DOMAIN=${VENDOR_DOMAIN}"
  build_arg_opts+=" --build-arg BUILD_IMAGE=tf-dev-sandbox:compile"

  if [[ -f ./$dir/.externals ]]; then
    local item=''
    for item in `cat ./$dir/.externals` ; do
      [ -z "$item" ] && continue
      local src=`echo $item | cut -d ':' -f 1`
      local dst=`echo $item | cut -d ':' -f 2`
      if [[ -z "$src" || -z "$dst" ]] ; then
        err "Building $container_name failed, invalid format of ./$dir/.externals" 2>&1 | append_log_file $logfile true
        was_errors=1
        return $exit_code
      fi
      rsync -r --exclude $dst --exclude-from='../.gitignore' ./$dir/$src ./$dir/$dst 2>&1 | append_log_file $logfile
    done
  fi

  log "Building args: $build_arg_opts" | append_log_file $logfile true
  local target_name="${CONTRAIL_REGISTRY}/${container_name}:${tag}"

  sudo docker build -t $target_name $opensdn_target_name_build_option \
    ${build_arg_opts} -f $docker_file ${opts} $dir 2>&1 | append_log_file $logfile
  exit_code=${PIPESTATUS[0]}
  local duration=$(date +"%s")
  (( duration -= start_time ))
  log "Docker build duration: $duration seconds" | append_log_file $logfile
  if [ $exit_code -eq 0 -a ${CONTRAIL_REGISTRY_PUSH} -eq 1 ]; then
    sudo docker push $target_name 2>&1 | append_log_file $logfile
    exit_code=${PIPESTATUS[0]}

    #TODO: remove after full switch to "opensdn-" prefix
    if [[ -n "$opensdn_target_name" ]]; then
      sudo docker push $opensdn_target_name  2>&1 | append_log_file $logfile
    fi
  fi
  duration=$(date +"%s")
  (( duration -= start_time ))
  if [ ${exit_code} -eq 0 ]; then
    log "Building $container_name finished successfully, duration: $duration seconds" | append_log_file $logfile true
    if [[ "${CONTRAIL_KEEP_LOG_FILES,,}" != 'true' ]] ; then
      rm -f $logfile
    fi
  else
    err "Building $container_name failed, duration: $duration seconds" 2>&1 | append_log_file $logfile true
    was_errors=1
  fi

  sudo docker images 2>&1 | append_log_file $logfile true

  return $exit_code
}

function process_dir() {
  local dir=${1%/}
  local docker_file="$dir/Dockerfile"
  local res=0
  if [[ -f "$docker_file" ]] ; then
    process_container "$dir" "$docker_file" || res=1
    return $res
  fi
  for d in $(ls -d $dir/*/ 2>/dev/null); do
    if [[ $d != "./" && $d == */general-base* ]]; then
      process_dir $d || res=1
    fi
  done
  for d in $(ls -d $dir/*/ 2>/dev/null); do
    if [[ $d != "./" && $d == */base* ]]; then
      process_dir $d || res=1
    fi
  done
  for d in $(ls -d $dir/*/ 2>/dev/null); do
    if [[ $d != "./" && $d != *base* ]]; then
      process_dir $d || res=1
    fi
  done
  return $res
}

function update_file() {
  local file=$1
  local new_content=$2
  local content_encoded=${3:-'false'}
  local file_md5=${file}.md5
  if [[ -f "$file" && -f "$file_md5" ]] ; then
    log "$file and it's checksum "$file_md5" are exist, check them"
    local new_md5
    if [[ "$content_encoded" == 'true' ]] ; then
      new_md5=`echo "$new_content" | base64 --decode | md5sum | awk '{print($1)}'`
    else
      new_md5=`echo "$new_content" | md5sum | awk '{print($1)}'`
    fi
    local old_md5=`cat "$file_md5" | awk '{print($1)}'`
    if [[ "$old_md5" == "$new_md5" ]] ; then
      log "content of $file is not changed"
      return
    fi
  fi
  log "update $file and it's checksum $file_md5"
  if [[ "$content_encoded" == 'true' ]] ; then
    echo "$new_content" | base64 --decode > "$file"
  else
    echo "$new_content" > "$file"
  fi
  md5sum "$file" > "$file_md5"
}

function update_yum_repos() {
  local rfile
  for rfile in $(ls $my_dir/../*.repo.template) ; do
    local content=$(cat "$rfile" | sed -e "s|\${CONTRAIL_REPOSITORY}|${CONTRAIL_REPOSITORY}|g")
    local dfile=$(basename $rfile | sed 's/.template//')
    update_file "general-base/$dfile" "$content"
    # this is special case - image derived directly from ubuntu image
    update_file "vrouter/kernel-build-init/$dfile" "$content"
    update_file "vrouter/kernel-init/$dfile" "$content"
    update_file "vrouter/kernel-init-centos/$dfile" "$content"
  done
}

function update_apt_repos() {
  local rfile="$my_dir/../sources.list"
  if [ -e "$rfile" ]; then
    local content=$(cat "$rfile")
    update_file "vrouter/kernel-build-init/sources.list" "$content"
    update_file "vrouter/plugin/mellanox/init/ubuntu/sources.list" "$content"
  fi
}

function process_list() {
  local list="$@"
  local i=''
  local jobs=''
  log "process list: $list"
  for i in $list ; do
    process_dir $i &
    jobs+=" $!"
  done
  local res=0
  for i in $jobs ; do
    wait $i || {
      res=1
      was_errors=1
    }
  done
  return $res
}

function process_all_parallel() {
  local full_list=$($my_dir/build.sh list | grep -v INFO)
  process_list general-base || return 1
  process_list base || return 1
  local list=$(echo "$full_list" | grep 'external\|\/base')
  process_list $list || return 1
  local list=$(echo "$full_list" | grep -v 'external\|base')
  process_list $list || return 1
}

if [[ $path == 'list' ]] ; then
  op='list'
  path="."
elif [[ "${CONTRAIL_PARALLEL_BUILD,,}" == 'true' ]] ; then
  op='build_parallel'
else
  op='build'
fi

if [ -z $path ] || [ $path = 'all' ]; then
  path="."
fi

log "starting build from $my_dir with relative path $path"
pushd $my_dir &>/dev/null

case $op in
  'build_parallel')
    log "prepare Contrail repo file in base image"
    update_yum_repos
    update_apt_repos
    if [[ "$path" == "." || "$path" == "all" ]] ; then
      process_all_parallel
    else
      process_dir $path
    fi
    ;;

  'build')
    log "prepare Contrail repo file in base image"
    update_yum_repos
    update_apt_repos
    process_dir $path
    ;;

  *)
    # either list or individual container
    process_dir $path
    ;;
esac

popd &>/dev/null

if [ $was_errors -ne 0 ]; then
  log_files=$(ls -l $my_dir/*.log)
  err "Failed to build some containers, see log files:\n$log_files"
  exit 1
fi
