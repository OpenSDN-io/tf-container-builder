#!/bin/bash
source /common.sh

pre_start_init
wait_for_cassandra

K8S_TOKEN_FILE=${K8S_TOKEN_FILE:-'/var/run/secrets/kubernetes.io/serviceaccount/token'}
K8S_TOKEN=${K8S_TOKEN:-"$(cat $K8S_TOKEN_FILE)"}

host_ip=$(get_listen_ip_for_node KUBEMANAGER)

if [[ "$CONFIGDB_CASSANDRA_DRIVER" == "cql" ]] ; then
    cassandra_server_list=$(echo $CONFIGDB_CQL_SERVERS | sed 's/,/ /g')
else
    cassandra_server_list=$(echo $CONFIGDB_SERVERS | sed 's/,/ /g')
fi

mkdir -p /etc/contrail
cat > /etc/contrail/contrail-kubernetes.conf << EOM
[DEFAULTS]
host_ip=${host_ip}
orchestrator=${CLOUD_ORCHESTRATOR}
token=$K8S_TOKEN
log_file=$CONTAINER_LOG_DIR/contrail-kube-manager.log
log_level=$LOG_LEVEL
log_local=$LOG_LOCAL
nested_mode=${KUBEMANAGER_NESTED_MODE:-"0"}
http_server_ip=$(get_introspect_listen_ip_for_node KUBEMANAGER)

[KUBERNETES]
kubernetes_api_server=${KUBERNETES_API_SERVER:-${DEFAULT_LOCAL_IP}}
kubernetes_api_port=${KUBERNETES_API_PORT:-8080}
kubernetes_api_secure_port=${KUBERNETES_API_SECURE_PORT:-6443}
kubernetes_cluster_domain=${KUBERNETES_CLUSTER_DOMAIN:-"default-domain"}
cluster_name=${KUBERNETES_CLUSTER_NAME}
cluster_project=${KUBERNETES_CLUSTER_PROJECT:-"{}"}
cluster_network=${KUBERNETES_CLUSTER_NETWORK:-"{}"}
pod_subnets=${KUBERNETES_POD_SUBNETS:-"10.32.0.0/12"}
ip_fabric_subnets=${KUBERNETES_IP_FABRIC_SUBNETS:-"10.64.0.0/12"}
service_subnets=${KUBERNETES_SERVICE_SUBNETS:-"10.96.0.0/12"}
ip_fabric_forwarding=${KUBERNETES_IP_FABRIC_FORWARDING:-"false"}
ip_fabric_snat=${KUBERNETES_IP_FABRIC_SNAT:-"false"}
host_network_service=${KUBERNETES_HOST_NETWORK_SERVICE:-"false"}

[VNC]
public_fip_pool=${KUBERNETES_PUBLIC_FIP_POOL:-"{}"}
vnc_endpoint_ip=$CONFIG_NODES
vnc_endpoint_port=$CONFIG_API_PORT

rabbit_server=$RABBITMQ_NODES
rabbit_port=$RABBITMQ_NODE_PORT
$rabbit_config
$kombu_ssl_config

cassandra_driver=$CONFIGDB_CASSANDRA_DRIVER
cassandra_server_list=$cassandra_server_list
cassandra_use_ssl=${CASSANDRA_SSL_ENABLE,,}
cassandra_ca_certs=$CASSANDRA_SSL_CA_CERTFILE
collectors=$COLLECTOR_SERVERS
zk_server_ip=$ZOOKEEPER_SERVERS

$sandesh_client_config

$collector_stats_config
EOM

if [[ $AUTH_MODE == "keystone" ]]; then
    cat >> /etc/contrail/contrail-kubernetes.conf << EOM
[AUTH]
auth_user=${KEYSTONE_AUTH_ADMIN_USER:-''}
auth_password=${KEYSTONE_AUTH_ADMIN_PASSWORD:-''}
auth_tenant=${KEYSTONE_AUTH_ADMIN_TENANT:-''}
auth_token_url=$KEYSTONE_AUTH_PROTO://${KEYSTONE_AUTH_HOST}:${KEYSTONE_AUTH_ADMIN_PORT}${KEYSTONE_AUTH_URL_TOKENS}
EOM
fi

add_ini_params_from_env KUBERNETES /etc/contrail/contrail-kubernetes.conf

set_third_party_auth_config
set_vnc_api_lib_ini

upgrade_old_logs "kube-manager"

run_service "$@"
