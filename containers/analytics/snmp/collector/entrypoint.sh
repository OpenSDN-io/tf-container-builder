#!/bin/bash

source /common.sh
export SNMPCONFPATH=${SNMPCONFPATH:-/etc/contrail}

pre_start_init
wait_for_cassandra

host_ip=$(get_listen_ip_for_node ANALYTICS_SNMP)
rabbitmq_server_list=$(echo $RABBITMQ_SERVERS | sed 's/,/ /g')
if [[ "$CONFIGDB_CASSANDRA_DRIVER" == "cql" ]] ; then
  config_db_server_list=$(echo $CONFIGDB_CQL_SERVERS | sed 's/,/ /g')
else
  config_db_server_list=$(echo $CONFIGDB_SERVERS | sed 's/,/ /g')
fi

mkdir -p /etc/contrail
cat > /etc/contrail/tf-snmp-collector.conf << EOM
[DEFAULTS]
host_ip=${host_ip}
scan_frequency=${SNMPCOLLECTOR_SCAN_FREQUENCY:-600}
fast_scan_frequency=${SNMPCOLLECTOR_FAST_SCAN_FREQUENCY:-60}
http_server_ip=$(get_introspect_listen_ip_for_node ANALYTICS_SNMP)
http_server_port=${SNMPCOLLECTOR_INTROSPECT_LISTEN_PORT:-$SNMPCOLLECTOR_INTROSPECT_PORT}
log_file=$CONTAINER_LOG_DIR/tf-snmp-collector.log
log_level=$LOG_LEVEL
log_local=$LOG_LOCAL
collectors=$COLLECTOR_SERVERS
zookeeper=$ZOOKEEPER_SERVERS

[API_SERVER]
api_server_list=$CONFIG_SERVERS
api_server_use_ssl=${CONFIG_API_SSL_ENABLE}

[CONFIGDB]
config_db_server_list=$config_db_server_list
config_db_use_ssl=${CASSANDRA_SSL_ENABLE,,}
config_db_ca_certs=$CASSANDRA_SSL_CA_CERTFILE
cassandra_driver=$CONFIGDB_CASSANDRA_DRIVER

rabbitmq_server_list=$rabbitmq_server_list
$rabbitmq_config
$rabbitmq_ssl_config

$sandesh_client_config

$collector_stats_config
EOM

add_ini_params_from_env SNMP_COLLECTOR /etc/contrail/tf-snmp-collector.conf

set_third_party_auth_config
set_vnc_api_lib_ini

upgrade_old_logs "snmp-collector"

run_service "$@"
