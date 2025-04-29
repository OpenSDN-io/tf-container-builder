#!/bin/bash
# Internal script for parsing common.env. Run by other executable scripts

[[ "${DEBUG,,}" != 'true' ]] || set -x

env_dir="${BASH_SOURCE%/*}"
if [[ ! -d "$env_dir" ]]; then env_dir="$PWD"; fi
env_file="$env_dir/common.env"
if [ -f $env_file ]; then
  source $env_file
  export ENV_FILE="$env_file"
fi

default_interface=`ip route show | grep "default via" | awk '{print $5}'`
default_gateway=`ip route show dev $default_interface | grep default | awk '{print $3}'`

linux_id=$(awk -F"=" '/^ID=/{print $2}' /etc/os-release | tr -d '"')
if [[ "$linux_id" == 'centos' ]] ; then
  # ver id is taken from available versions from docker.io
  linux_ver_id=`cat /etc/redhat-release | awk '{print($4)}'`
else
  # for ubuntu ver id matchs 14.04, 16.04
  # for rhel ver id matchs 7.9, 8.4
  linux_ver_id=$(awk -F"=" '/^VERSION_ID=/{print $2}' /etc/os-release | tr -d '"')
fi

# target platform info
export LINUX_DISTR=${LINUX_DISTR:-centos}
export LINUX_DISTR_VER=${LINUX_DISTR_VER:-}
if [[ -z "$LINUX_DISTR_VER" ]] ; then
  if [[ "$LINUX_DISTR" =~ 'centos' ]] ; then
    LINUX_DISTR_VER=7
  else
    LINUX_DISTR_VER='latest'
  fi
fi

# ubuntu version for vrouter kernel build init and mellanox ubuntu containers
export UBUNTU_DISTR=${UBUNTU_DISTR:-ubuntu}
export UBUNTU_DISTR_VERSION=${UBUNTU_DISTR_VER:-24.04}

# build platform info
export LINUX_ID=$linux_id
export LINUX_VER_ID=$linux_ver_id

export HOST_IP=${HOST_IP:-'auto'}
if [[ $HOST_IP == 'auto' ]] ; then
  export HOST_IP=`ip address show dev $default_interface | head -3 | tail -1 | tr "/" " " | awk '{print $2}'`
fi

# To enable installation Contrail from sources set this variable to
# the root of build dir on host, e.g. /root/contrail
# It should be root created by scons.
# (SRC_ROOT - is used as default to inherit value from TF CI)
export CONTRAIL_SOURCE=${CONTRAIL_SOURCE:-'/root/contrail'}

export K8S_VERSION=${K8S_VERSION:-'1.15.4'}
if [[ "$LINUX_DISTR" =~ 'ubi8' ]] ; then
  export OPENSTACK_VERSION=${OPENSTACK_VERSION:-'train'}
else
  export OPENSTACK_VERSION=${OPENSTACK_VERSION:-'queens'}
fi

export CONTAINER_NAME_PREFIX=${CONTAINER_NAME_PREFIX:-'opensdn'}
# CONTRAIL_VERSION is deprecated.
# For Compatibility with Juniper CI. Will be removed.
[ -z "$CONTRAIL_CONTAINER_TAG" ] && [ -n "$CONTRAIL_VERSION" ] && CONTRAIL_CONTAINER_TAG=$CONTRAIL_VERSION
export CONTRAIL_CONTAINER_TAG=${CONTRAIL_CONTAINER_TAG:-'dev'}

export CONTRAIL_REGISTRY=${CONTRAIL_REGISTRY:-'auto'}
export CONTRAIL_REGISTRY_PUSH=${CONTRAIL_REGISTRY_PUSH:-1}
export CONTRAIL_REPOSITORY=${CONTRAIL_REPOSITORY:-'auto'}
default_registry_ip=${_CONTRAIL_REGISTRY_IP:-${HOST_IP}}
if [[ $CONTRAIL_REGISTRY == 'auto' ]] ; then
  export CONTRAIL_REGISTRY="${default_registry_ip}:5000"
fi
if [[ $CONTRAIL_REPOSITORY == 'auto' ]] ; then
  export CONTRAIL_REPOSITORY="http://${default_registry_ip}/${CONTRAIL_CONTAINER_TAG}"
fi
export CONTRAIL_PARALLEL_BUILD=${CONTRAIL_PARALLEL_BUILD:-'false'}
export CONTRAIL_KEEP_LOG_FILES=${CONTRAIL_KEEP_LOG_FILES:-'false'}

export GENERAL_EXTRA_RPMS=${GENERAL_EXTRA_RPMS-""}
# use some stable OpenStack repo for Contrail's dependencies
export BASE_EXTRA_RPMS=${BASE_EXTRA_RPMS-"https://repos.fedorapeople.org/repos/openstack/EOL/openstack-queens/rdo-release-queens-2.noarch.rpm"}
export DOCKER_REPO=${DOCKER_REPO:-'https://download.docker.com/linux/centos/docker-ce.repo'}

export CONTROLLER_NODES=${CONTROLLER_NODES:-$HOST_IP}
export AGENT_NODES=${AGENT_NODES:-$CONTROLLER_NODES}
export ANALYTICS_NODES=${ANALYTICS_NODES:-$CONTROLLER_NODES}
export ANALYTICSDB_NODES=${ANALYTICSDB_NODES:-$CONTROLLER_NODES}
export ANALYTICS_SNMP_NODES=${ANALYTICS_SNMP_NODES:-$ANALYTICS_NODES}
export ANALYTICS_ALARM_NODES=${ANALYTICS_ALARM_NODES:-$ANALYTICSDB_NODES}
export CONFIG_NODES=${CONFIG_NODES:-$CONTROLLER_NODES}
export CONFIGDB_NODES=${CONFIGDB_NODES:-$CONFIG_NODES}
export CONTROL_NODES=${CONTROL_NODES:-$CONFIG_NODES}
export KAFKA_NODES=${KAFKA_NODES:-$ANALYTICS_ALARM_NODES}
export LOG_LEVEL=${LOG_LEVEL:-'SYS_NOTICE'}
export METADATA_PROXY_SECRET=${METADATA_PROXY_SECRET:-'contrail'}
export PHYSICAL_INTERFACE=${PHYSICAL_INTERFACE:-$default_interface}
export VROUTER_GATEWAY=${VROUTER_GATEWAY:-$default_gateway}
export RABBITMQ_NODES=${RABBITMQ_NODES:-$CONFIGDB_NODES}
export RABBITMQ_NODE_PORT=${RABBITMQ_NODE_PORT:-'5673'}
export WEBUI_NODES=${WEBUI_NODES:-$CONTROLLER_NODES}
export ZOOKEEPER_NODES=${ZOOKEEPER_NODES:-$CONFIG_NODES}
export ZOOKEEPER_PORT=${ZOOKEEPER_PORT:-'2181'}
export ZOOKEEPER_PORTS=${ZOOKEEPER_PORTS:-'2888:3888'}

export ANALYTICS_API_VIP=${ANALYTICS_API_VIP}
export CONFIG_API_VIP=${CONFIG_API_VIP}

export AAA_MODE=${AAA_MODE:-'no-auth'}
export AUTH_MODE=${AUTH_MODE:-'noauth'}
export CLOUD_ORCHESTRATOR=${CLOUD_ORCHESTRATOR:-'none'}

export KUBERNETES_API_SERVER=${KUBERNETES_API_SERVER:-$HOST_IP}
export KUBERNETES_API_SECURE_PORT=${KUBERNETES_API_SECURE_PORT:-'6443'}
export KUBERNETES_IP_FABRIC_SNAT=${KUBERNETES_IP_FABRIC_SNAT:-'false'}
export KUBERNETES_IP_FABRIC_FORWARDING=${KUBERNETES_IP_FABRIC_FORWARDING:-'true'}

export DPDK_UIO_DRIVER=${DPDK_UIO_DRIVER:-'uio_pci_generic'}
export CPU_CORE_MASK=${CPU_CORE_MASK:-'0x01'}
export SERVICE_CORE_MASK=${SERVICE_CORE_MASK:-}
export DPDK_CTRL_THREAD_MASK=${DPDK_CTRL_THREAD_MASK:-}
export HUGE_PAGES=${HUGE_PAGES:-""}
export NIC_OFFLOAD_ENABLE=${NIC_OFFLOAD_ENABLE:-False}
export DPDK_ENABLE_VLAN_FWRD=${DPDK_ENABLE_VLAN_FWRD:-False}

export JVM_EXTRA_OPTS=${JVM_EXTRA_OPTS:-'-Xms1g -Xmx2g'}

#TLS options
export SSL_ENABLE=${SSL_ENABLE:-False}
export SSL_INSECURE=${SSL_INSECURE:-True}
export SERVER_CERTFILE=${SERVER_CERTFILE:-'/etc/contrail/ssl/certs/server.pem'}
export SERVER_KEYFILE=${SERVER_KEYFILE:-'/etc/contrail/ssl/private/server-privkey.pem'}
export SERVER_CA_CERTFILE=${SERVER_CA_CERTFILE:-'/etc/contrail/ssl/certs/ca-cert.pem'}
export SERVER_CA_KEYFILE=${SERVER_CA_KEYFILE:-'/etc/contrail/ssl/private/ca-key.pem'}

export XMPP_SSL_ENABLE=${XMPP_SSL_ENABLE:-${SSL_ENABLE}}
export XMPP_SERVER_CERTFILE=${XMPP_SERVER_CERTFILE:-${SERVER_CERTFILE}}
export XMPP_SERVER_KEYFILE=${XMPP_SERVER_KEYFILE:-${SERVER_KEYFILE}}
export XMPP_SERVER_CA_CERTFILE=${XMPP_SERVER_CA_CERTFILE:-${SERVER_CA_CERTFILE}}

export CONFIG_API_SSL_ENABLE=${CONFIG_API_SSL_ENABLE:-${SSL_ENABLE}}
export CONFIG_API_SERVER_CERTFILE=${CONFIG_API_SERVER_CERTFILE:-${SERVER_CERTFILE}}
export CONFIG_API_SERVER_KEYFILE=${CONFIG_API_SERVER_KEYFILE:-${SERVER_KEYFILE}}
export CONFIG_API_SERVER_CA_CERTFILE=${CONFIG_API_SERVER_CA_CERTFILE:-${SERVER_CA_CERTFILE}}

export ANALYTICS_API_SSL_ENABLE=${ANALYTICS_API_SSL_ENABLE:-${SSL_ENABLE}}
export ANALYTICS_API_SSL_INSECURE=${ANALYTICS_API_SSL_INSECURE:-${SSL_INSECURE}}
export ANALYTICS_API_SERVER_CERTFILE=${ANALYTICS_API_SERVER_CERTFILE:-${SERVER_CERTFILE}}
export ANALYTICS_API_SERVER_KEYFILE=${ANALYTICS_API_SERVER_KEYFILE:-${SERVER_KEYFILE}}
export ANALYTICS_API_SERVER_CA_CERTFILE=${ANALYTICS_API_SERVER_CA_CERTFILE:-${SERVER_CA_CERTFILE}}

export INTROSPECT_SSL_ENABLE=${INTROSPECT_SSL_ENABLE:-${SSL_ENABLE}}
export INTROSPECT_SSL_INSECURE=${INTROSPECT_SSL_INSECURE:-${SSL_INSECURE}}
export INTROSPECT_CERTFILE=${INTROSPECT_CERTFILE:-${SERVER_CERTFILE}}
export INTROSPECT_KEYFILE=${INTROSPECT_KEYFILE:-${SERVER_KEYFILE}}
export INTROSPECT_CA_CERTFILE=${INTROSPECT_CA_CERTFILE:-${SERVER_CA_CERTFILE}}

export SANDESH_SSL_ENABLE=${SANDESH_SSL_ENABLE:-${SSL_ENABLE}}
export SANDESH_CERTFILE=${SANDESH_CERTFILE:-${SERVER_CERTFILE}}
export SANDESH_KEYFILE=${SANDESH_KEYFILE:-${SERVER_KEYFILE}}
export SANDESH_SERVER_KEYFILE=${SANDESH_SERVER_KEYFILE:-${SANDESH_KEYFILE}}
export SANDESH_SERVER_CERTFILE=${SANDESH_SERVER_CERTFILE:-${SANDESH_CERTFILE}}
export SANDESH_CA_CERTFILE=${SANDESH_CA_CERTFILE:-${SERVER_CA_CERTFILE}}

export KEYSTONE_AUTH_PROTO=${KEYSTONE_AUTH_PROTO:-'http'}
export KEYSTONE_AUTH_INSECURE=${KEYSTONE_AUTH_INSECURE:-${SSL_INSECURE}}
export KEYSTONE_AUTH_CERTFILE=${KEYSTONE_AUTH_CERTFILE:-}
export KEYSTONE_AUTH_KEYFILE=${KEYSTONE_AUTH_KEYFILE:-}
export KEYSTONE_AUTH_CA_CERTFILE=${KEYSTONE_AUTH_CA_CERTFILE:-}

# SSL opts for RabbitMQ server
export RABBITMQ_SSL_CERTFILE=${RABBITMQ_SSL_CERTFILE:-${SERVER_CERTFILE}}
export RABBITMQ_SSL_KEYFILE=${RABBITMQ_SSL_KEYFILE:-${SERVER_KEYFILE}}
export RABBITMQ_SSL_CACERTFILE=${RABBITMQ_SSL_CACERTFILE:-${SERVER_CA_CERTFILE}}

# client options for RabbitMQ
export RABBITMQ_USE_SSL=${RABBITMQ_USE_SSL:-False}
export RABBITMQ_SSL_VER=${RABBITMQ_SSL_VER:-'tlsv1.2'}
export RABBITMQ_CLIENT_SSL_CERTFILE=${RABBITMQ_CLIENT_SSL_CERTFILE:-${RABBITMQ_SSL_CERTFILE}}
export RABBITMQ_CLIENT_SSL_KEYFILE=${RABBITMQ_CLIENT_SSL_KEYFILE:-${RABBITMQ_SSL_KEYFILE}}
export RABBITMQ_CLIENT_SSL_CACERTFILE=${RABBITMQ_CLIENT_SSL_CACERTFILE:-${RABBITMQ_SSL_CACERTFILE}}

# Metadata service SSL opts
export METADATA_SSL_ENABLE=${METADATA_SSL_ENABLE:-false}
export METADATA_SSL_CERTFILE=${METADATA_SSL_CERTFILE:-}
export METADATA_SSL_KEYFILE=${METADATA_SSL_KEYFILE:-}
export METADATA_SSL_CA_CERTFILE=${METADATA_SSL_CA_CERTFILE:-}
export METADATA_SSL_CERT_TYPE=${METADATA_SSL_CERT_TYPE:-}

# Redis SSL options
export REDIS_SSL_ENABLE=${REDIS_SSL_ENABLE:-False}
export REDIS_SSL_CERTFILE=${REDIS_SSL_CERTFILE:-${SERVER_CERTFILE}}
export REDIS_SSL_KEYFILE=${REDIS_SSL_KEYFILE:-${SERVER_KEYFILE}}
export REDIS_SSL_CACERTFILE=${REDIS_SSL_CACERTFILE-${SERVER_CA_CERTFILE}}


# VRouter kernel module init image.
if [[ "$VROUTER_DPDK" == True ]] ; then
    export VROUTER_KERNEL_INIT_IMAGE='opensdn-vrouter-kernel-init-dpdk'
elif [[ "$LINUX_DISTR" =~ 'ubuntu' ]] ; then
    export VROUTER_KERNEL_INIT_IMAGE='opensdn-vrouter-kernel-build-init'
elif [[ "$LINUX_DISTR" =~ 'rocky' ]] ; then
    export VROUTER_KERNEL_INIT_IMAGE='opensdn-vrouter-kernel-init'
else
    export VROUTER_KERNEL_INIT_IMAGE='opensdn-vrouter-kernel-init-centos'
fi

# export vendor label info for containers
export VENDOR_NAME=${VENDOR_NAME:-'Juniper'}
export VENDOR_DOMAIN=${VENDOR_DOMAIN:-'net.juniper.contrail'}
