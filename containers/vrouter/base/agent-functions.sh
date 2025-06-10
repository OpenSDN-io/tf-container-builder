#!/bin/bash

source /network-functions-vrouter-${AGENT_MODE}

# Three signal handlers for vrouter-agent container
function trap_vrouter_agent_quit() {
    term_process $(cat /var/run/vrouter-agent.pid)
    remove_vhost0
    cleanup_vrouter_agent_files
}

function trap_vrouter_agent_term() {
    term_process $(cat /var/run/vrouter-agent.pid)
}

function trap_vrouter_agent_hup() {
    # TODO when vrouter agent binary will support SIGHUP
    # We can just run " kill -HUP $(cat /var/run/vrouter-agent.pid) "
    # But now we have to restart agent process for reload agent config file
    touch /var/run/restart_agent
    term_process $(cat /var/run/vrouter-agent.pid)
}

function get_default_gateway_for_nic() {
  local nic=$1
  ip route show dev $nic | grep default | head -n 1 | awk '{print $3}'
}

function get_default_vrouter_gateway() {
    local node_ip=$(resolve_1st_control_node_ip)
    local gw=$(get_gateway_nic_for_ip $node_ip)
    get_default_gateway_for_nic $gw
}

function create_vhost_network_functions() {
    local dir=$1
    pushd "$dir"
    # Update /dhclient-vhost0.conf with the system /etc/dhcp/dhclient.conf
    [ -e /etc/dhcp/dhclient.conf ] && cat /etc/dhcp/dhclient.conf >> /dhclient-vhost0.conf

    /bin/cp -f /ifup-vhost /ifdown-vhost /dhclient-vhost0.conf ./
    chmod 744 ./ifup-vhost ./ifdown-vhost ./dhclient-vhost0.conf
    /bin/cp -f  /network-functions-vrouter /network-functions-vrouter-${AGENT_MODE} ./
    chmod 644 ./network-functions-vrouter ./network-functions-vrouter-${AGENT_MODE}
    if [ -f /network-functions-vrouter-${AGENT_MODE}-env ] ; then
        local _ct=$(cat /network-functions-vrouter-${AGENT_MODE}-env)
        eval "echo \"$_ct\"" > ./network-functions-vrouter-${AGENT_MODE}-env
        chmod 644 ./network-functions-vrouter-${AGENT_MODE}-env
    fi
    popd
}

function prepare_network_scripts() {
    # copy requried ifup scripts if missed
    # (on rhel8 system network-script rpm might be not installed)
    local dst=$1
    local src='/opt/contrail/network-scripts'
    if [ ! -d $src ] || [ ! -d $dst ] ; then
        return
    fi
    local i
    for i in $(ls $src) ; do
        if [ ! -e ${dst}/$i ] ; then
            cp -r ${src}/$i ${dst}/$i
        fi
    done
}

function copy_agent_tools_to_host() {
    # copy ifup-vhost
    local netscript_dir='/etc/sysconfig/network-scripts'
    if [[ -d "$netscript_dir" ]] ; then
        create_vhost_network_functions "$netscript_dir"
        prepare_network_scripts "$netscript_dir"
    fi
    # copy vif util
    /bin/cp -f /bin/vif /host/bin/vif
    chmod 644 /host/bin/vif
    chmod +x /host/bin/vif
}

function is_vlan() {
    local dev=${1:-?}
    [ -f "/proc/net/vlan/${dev}" ]
}

function get_vlan_parameters() {
    local dev=${1:-?}
    local vlan_file="/proc/net/vlan/${dev}"
    local vlan_id=''
    local vlan_parent=''
    if [[ -f "${vlan_file}" ]] ; then
        local vlan_data=$(cat "$vlan_file")
        vlan_id=`echo "$vlan_data" | grep 'VID:' | head -1 | awk '{print($3)}'`
        vlan_parent=`echo "$vlan_data" | grep 'Device:' | head -1 | awk '{print($2)}'`
        if [[ -n "$vlan_parent" ]] ; then
            dev=$vlan_parent
        fi
        echo $vlan_id $dev
    fi
}

function is_bonding() {
    local dev=${1:-?}
    [ -d "/sys/class/net/${dev}/bonding" ]
}

function get_bonding_parameters() {
    local dev=${1:-?}
    local bond_dir="/sys/class/net/${dev}/bonding"
    if [[ -d ${bond_dir} ]] ; then
        local mode="$(cat ${bond_dir}/mode | awk '{print $2}')"
        local policy="$(cat ${bond_dir}/xmit_hash_policy | awk '{print $1}')"
        local lacp_rate="$(cat ${bond_dir}/lacp_rate | awk '{print $2}')"
        policy=$(convert_bond_policy $policy)
        mode=$(convert_bond_mode $mode)

        local slaves="$(cat ${bond_dir}/slaves | tr ' ' '\n' | sort | tr '\n' ',')"
        slaves=${slaves%,}

        local pci_addresses=''
        local bond_numa=''
        ## Bond Members
        for slave in $(echo ${slaves} | tr ',' ' ') ; do
            local slave_dir="/sys/class/net/${slave}"
            local slave_pci=$(get_pci_address_for_nic $slave)
            if [[ -n "${slave_pci}" ]] ; then
                pci_addresses+=",${slave_pci}"
            fi
            if [ -z "${bond_numa}" ]; then
                bond_numa=$(get_bond_numa $slave_pci)
            fi
        done
        pci_addresses=${pci_addresses#,}

        echo "$mode $policy $slaves $pci_addresses $bond_numa $lacp_rate"
    fi
}

function ifquery_list() {
   grep --no-filename "DEVICE=" /etc/sysconfig/network-scripts/ifcfg-* | cut -c8- | tr -d '"' | sort | uniq
}

function ifquery_dev() {
    local dev=${1:-?}
    local if_file="/etc/sysconfig/network-scripts/ifcfg-$dev"
    if [ -e "$if_file" ] ; then
        if grep -q -e "^MASTER" -e "^SLAVE" "$if_file" ; then
            sed 's/\<MASTER=/bond-master: /g' "$if_file"
        else
            cat "$if_file"
        fi
    fi
}

function wait_bonding_slaves() {
    local dev=${1:-?}
    local bond_dir="/sys/class/net/${dev}/bonding"
    local ret=0
    for iface in $(ifquery_list) ; do
        if ifquery_dev $iface | grep "bond-master" | grep -q ${dev} ; then
            # Wait upto 60 sec till the interface is enslaved
            local i=0
            for i in {1..60} ; do
                if grep -q $iface "${bond_dir}/slaves" ; then
                    echo "INFO: Slave interface $iface ready"
                    i=0
                    break
                fi
                echo "Waiting for interface $iface to be ready... ${i}/60"
                sleep 1
            done
            [ "$i" != '60' ] || { ret=1 && echo "ERROR: failed to wait $iface to be enslaved" ; }
        fi
    done
    return $ret
}

function get_pci_address_for_nic() {
    local nic=${1:-?}
    if is_vlan $nic ; then
        local vlan_id=''
        local vlan_parent=''
        IFS=' ' read -r vlan_id vlan_parent <<< $(get_vlan_parameters $nic)
        nic=$vlan_parent
    fi
    if ! is_bonding $nic ; then
        ethtool -i ${nic} | grep bus-info | awk '{print $2}' | tr -d ' '
    else
        echo '0000:00:00.0'
    fi
}

function find_phys_nic_by_mac() {
    local mac=$1
    local nics=$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name vhost0 ! -name lo -printf "%P " -execdir cat {}/address \; | grep "$mac" | cut -s -d ' ' -f 1)
    [ -z "$nics" ] && return
    # nics may consists of several nics in case of bond/vlans
    # 1 - check vlans
    local n=''
    for n in $nics ; do
        if is_vlan $n ; then
            echo $n
            return
        fi
    done
    #2 - check bonds
    local n=''
    for n in $nics ; do
        if is_bonding $n ; then
            echo $n
            return
        fi
    done
    # check if only one nic is found
    # > 1 means that nic cannot be identified automatically
    local count=$(echo "$nics" | wc -l)
    if [[ $count != 1 ]] ; then
        return 1
    fi
    # just
    echo $nics
}

function get_physical_nic_and_mac()
{
  local nic='vhost0'
  local mac=$(get_iface_mac $nic)
  if [[ -n "$mac" ]] ; then
    # it means vhost0 iface is already up and running,
    # so try to find physical nic by MAC (which should be
    # the same as in vhost0)
    nic=`vif --list | grep "Type:Physical HWaddr:${mac}" -B1 | head -1 | awk '{print($3)}'`
    # WA: CEM-9368: there case when vif doesnt return phys device => try to read from ip link
    if [[ -z "$nic" ]] ; then
        nic=$(find_phys_nic_by_mac $mac)
    fi
    if [[ -n "$nic" && ! "$nic" =~ ^[0-9] ]] ; then
        # NIC case, for DPDK case nic is number, so use mac from vhost0 there
        local _mac=$(get_iface_mac $nic)
        if [[ -n "$_mac" ]] ; then
            mac=$_mac
        else
            echo "ERROR: unsupported agent mode" >&2
            return 1
        fi
    else
        # DPDK case, nic name is not exist, so set it to default
        nic=$(get_vrouter_physical_iface)
    fi
  else
    # there is no vhost0 device, so then get vrouter physical interface
    nic=$(get_vrouter_physical_iface)
    mac=$(get_iface_mac $nic)
  fi
  # Ensure that nic & mac are not empty
  if [[ "$nic" == '' || "$mac" == '' ]] ; then
      echo "ERROR: either phys nic or mac is empty: phys_int='$nic' phys_int_mac='$mac'" >&2
      return 1
  fi
  # Ensure nic is not wrongly detected as vhost0
  if [[ "$nic" == 'vhost0' ]] ; then
      echo "ERROR: Failed to lookup for phys_int for already running vhost0 with mac='$mac'" >&2
      return 1
  fi

  echo $nic $mac
}

function disable_chksum_offload() {
    local intf=$1
    local intf_type=`ethtool -i $intf | grep driver | cut -f 2 -d ' '`
    if [[ $intf_type == "vmxnet3" ]]; then
        ethtool --offload $intf rx off
        ethtool --offload $intf tx off
    fi
}

function disable_lro_offload() {
    local intf=$1
    ethtool --offload $intf lro off
}

function enable_hugepages_to_coredump() {
    local name=$1
    local pid=$(pidof $name)
    echo "INFO: enable hugepages to coredump for $name with pid=$pid"
    local coredump_filter="/proc/$pid/coredump_filter"
    local cdump_filter=0x73
    if [[ -f "$coredump_filter" ]] ; then
        cdump_filter=`cat "$coredump_filter"`
        cdump_filter=$((0x40 | 0x$cdump_filter))
    fi
    echo $cdump_filter > "$coredump_filter"
}

function probe_nic () {
    local nic=$1
    local probes=${2:-1}
    while (( probes > 0 )) ; do
        echo "INFO: Probe ${nic}... tries left $probes"
        local mac=$(get_iface_mac $nic)
        if [[ -n "$mac" ]]; then
            return 0
        fi
        (( probes -= 1))
        sleep 1
    done
    return 1
}

function wait_device_for_driver () {
    local driver=$1
    local pci_address=$2
    local i=0
    for i in {1..60} ; do
        echo "INFO: Waiting device $pci_address for driver ${driver} ... $i"
        if [[ -L /sys/bus/pci/drivers/${driver}/${pci_address} ]] ; then
            return 0
        fi
        sleep 2
    done
    return 1
}

function save_pci_info() {
    local pci=$1
    local binding_data_dir='/var/run/vrouter'
    local binding_data_file="${binding_data_dir}/${pci}"
    if [[ ! -e "$binding_data_file" ]] ; then
        local pci_data=`lspci -vmmks ${pci}`
        echo "INFO: Add lspci data to ${binding_data_file}"
        echo "$pci_data"
        echo "$pci_data" > ${binding_data_file}
    else
        echo "INFO: lspci data for $pci already exists"
    fi
}

function bind_devs_to_driver() {
    local driver=$1
    shift 1
    local pci=( $@ )
    # bind physical device(s) to DPDK driver
    local ret=0
    local n=''
    for n in ${pci[@]} ; do
        # save nic name before binding to dpdk driver
        local nic=$(get_ifname_by_pci $n)
        echo "INFO: Binding device $n to driver $driver ..."
        save_pci_info $n
        if ! /opt/contrail/bin/dpdk_nic_bind.py --force --bind="$driver" $n ; then
            echo "ERROR: Failed to bind $n to driver $driver"
            return 1
        fi
        [[ -z "$nic" ]] || bkp_ifcfg_file $nic
        if ! wait_device_for_driver $driver $n ; then
            echo "ERROR: Failed to wait device $n to appears for driver $driver"
            return 1
        fi
    done
}

function bkp_ifcfg_file() {
    if [[ "${KERNEL_INIT_VHOST0,,}" == 'true' ]] ; then
        echo "INFO: non-rhosp context, dont touch initial ifcfg-$1 file"
        return
    fi
    local d="/etc/sysconfig/network-scripts"
    [[ -e $d ]] || return
    pushd $d
    local f="ifcfg-$1"
    if [[ -e $f ]] ; then
        if [[ ! -e contrail.org.$f ]] ; then
            echo "INFO: backup $d/$f"
            mv $f contrail.org.$f
        else
            echo "INFO: remove $d/$f"
            rm -f $f
        fi
    fi
    popd
}

function read_phys_int_mac_pci_dpdk() {
    if [[ -z "$BIND_INT" ]] ; then
        declare phys_int phys_int_mac pci
        IFS=' ' read -r phys_int phys_int_mac <<< $(get_physical_nic_and_mac)
        pci=$(get_pci_address_for_nic $phys_int)
        echo $phys_int $phys_int_mac $pci
        return
    fi
    # in case of running from ifup in tripleo there is no way to read params from system,
    # all of them are to be available from ifcfg-vhost0 (that are passed via env to container)
    ifcfg_read_phys_int_mac_pci_dpdk
}

function read_and_save_dpdk_params_for_phys_int() {
    local phys_int=$1
    local phys_int_mac=$2
    local pci=$3
    local binding_data_dir='/var/run/vrouter'
    local addrs
    local mtu
    local routes
    if [ -z "$BIND_INT" ] ; then
        # read additional data from phys nic in non OSP case only
        addrs=$(get_addrs_for_nic $phys_int)
        mtu=$(get_iface_mtu $phys_int)
        routes=$(get_dev_routes $phys_int)
    fi

    echo "INFO: phys_int=$phys_int phys_int_mac=$phys_int_mac, pci=$pci, addrs=[$addrs], routes=[$routes]"
    local nic=$phys_int

    # save data for next usage in network init container
    mkdir -p ${binding_data_dir}

    echo "$phys_int_mac" > $binding_data_dir/${nic}_mac
    echo "$pci" > $binding_data_dir/${nic}_pci
    echo "$addrs" > $binding_data_dir/${nic}_ip_addresses
    echo "$mtu" > $binding_data_dir/${nic}_mtu
    echo "$routes" > $binding_data_dir/${nic}_routes

    declare vlan_id vlan_parent
    if [ -n "$BIND_INT" ] ; then
        # In case of OSP: VLAN_ID is set to if vlan is used.
        # so, no needs to resolve.
        vlan_id=$VLAN_ID
        vlan_parent=$phys_int
    else
        # read from system
        if is_vlan $phys_int ; then
            IFS=' ' read -r vlan_id vlan_parent <<< $(get_vlan_parameters $phys_int)
            phys_int=$vlan_parent
        fi
    fi
    if [ -n "$vlan_id" ] ; then
        echo "$vlan_id $vlan_parent" > $binding_data_dir/${nic}_vlan
        # change device for detecting othe options like PCIs, etc
        echo "INFO: vlan: echo vlan_id=$vlan_id vlan_parent=$vlan_parent"
    fi

    declare mode policy slaves pci bond_numa lacp_rate
    if [ -n "$BIND_INT" ] ; then
        # In case of OSP: params come from ifcfg.
        if [ -n "$BOND_MODE" ] ; then
            mode=$BOND_MODE
            policy=$(convert_bond_policy $BOND_POLICY)
            mode=$(convert_bond_mode ${mode})
            slaves=''
            declare _slave
            for _slave in ${BIND_INT//,/ } ; do
                [ -n "$slaves" ] && slaves+=','
                slaves+="$(get_ifname_by_pci $_slave)"
            done
            pci=$BIND_INT
            _slave=$(echo ${slaves//,/ } | cut -d ',' -f 1)
            bond_numa=$(get_bond_numa $_slave)
            echo "$pci"  > $binding_data_dir/${nic}_pci
            lacp_rate=${LACP_RATE:-0}
        fi
    else
        # read from system
        if is_bonding $phys_int ; then
            wait_bonding_slaves $phys_int
            IFS=' ' read -r mode policy slaves pci bond_numa lacp_rate <<< $(get_bonding_parameters $phys_int)
            echo "$pci" > $binding_data_dir/${nic}_pci
        fi
    fi
    if [ -n "$mode" ] ; then
        echo "$mode $policy $slaves $pci $bond_numa $lacp_rate" > $binding_data_dir/${nic}_bond
        echo "INFO: bonding: $mode $policy $slaves $pci $bond_numa $lacp_rate"
    fi
}

function l3mh_nics() {
    if [ -n "$PHYSICAL_INTERFACE" ] ; then
        echo ${PHYSICAL_INTERFACE//,/ }
        return
    fi
    # derive NICs via route if provided by user
    local control_node_ip=${1:-$(resolve_1st_control_node_ip)}
    local nics=$(ip route show $control_node_ip | grep "nexthop via" | awk '{print $5}' | sort -u | tr '\n' ' ')
    if [[ -n "$nics" ]] ; then
        echo "$nics"
        return
    fi
    # derive via GWs
    local i
    for i in ${VROUTER_GATEWAY//,/ } ; do
        [ -z "$nics" ] || nics+=" "
        nics+=$(ip route get $i | grep -o ' dev .*' | awk '{print($2)}' | grep -v '^lo$')
    done
    [ -z "$nics" ] || echo "$nics" | tr ' ' '\n' | sort -u | xargs
}

function l3mh_gw() {
    if [ -n "$VROUTER_GATEWAY" ] ; then
        echo ${VROUTER_GATEWAY//,/ }
        return
    fi
    local control_node_ip=${1:-$(resolve_1st_control_node_ip)}
    ip route show $control_node_ip | grep "nexthop via" | awk '{print $3}' | tr '\n' ' '
}

function read_and_save_dpdk_params() {
    local binding_data_dir='/var/run/vrouter'
    if [ -s $binding_data_dir/nic ] ; then
        echo "WARNING: binding information is already saved"
        return
    fi

    declare phys_int phys_int_mac pci

    if [[ -n "$L3MH_CIDR" ]]; then
        local control_node_ip=$(resolve_1st_control_node_ip)
        local phys_ints=$(l3mh_nics $control_node_ip)
        local nic_list=''
        for phys_int in $phys_ints; do
            phys_int_mac=$(get_iface_mac $phys_int)
            pci=$(get_pci_address_for_nic $phys_int)
            read_and_save_dpdk_params_for_phys_int $phys_int $phys_int_mac $pci
            if [ -z $nic_list ]; then
                nic_list+=$phys_int
            else
                nic_list+=" $phys_int"
            fi
        done
        #Get static dpdk routes 1st control node
        local static_route=$(get_static_dpdk_route $control_node_ip)
        echo "$static_route" > $binding_data_dir/static_dpdk_routes
        echo "INFO: saving dpdk static route: $static_route"
        # Save this file latest because it is used
        # as an sign that params where saved succesfully
        echo "$nic_list" > $binding_data_dir/nic
    else
        IFS=' ' read -r phys_int phys_int_mac pci <<< $(read_phys_int_mac_pci_dpdk)
        read_and_save_dpdk_params_for_phys_int $phys_int $phys_int_mac $pci
        # Save this file latest because it is used
        # as an sign that params where saved succesfully
        echo "$phys_int" > $binding_data_dir/nic
    fi

}

function ensure_hugepages() {
    local hp_dir=${1:?}
    hp_dir=${hp_dir/%\/}
    local mp
    local fs
    for mp in $(mount -t hugetlbfs | awk '{print($3)}') ; do
        if [[ "$mp" == "$hp_dir" ]] ; then
            return
        fi
    done
    echo "ERROR: Hupepages dir($hp_dir) does not have hugetlbfs mount type"
    exit -1
}

function check_vrouter_agent_settings() {

    if [ -n "$L3MH_CIDR" ] ; then
        echo "WARNING: check_vrouter_agent_settings is skiped for l3mh."
        return
    fi

    # check that all control nodes accessible via the same interface and this interface is vhost0
    local nodes=(`echo $CONTROL_NODES | tr ',' ' '`)
    if [[ ${#nodes} == 0 ]]; then
        echo "ERROR: CONTROL_NODES list is empty or incorrect ($CONTROL_NODES)."
        echo "ERROR: Please define CONTROL_NODES list."
        return 1
    fi

    local resolved_ip=$(resolve_host_ip ${nodes[0]})
    local iface=$(get_gateway_nic_for_ip $resolved_ip)
    if [[ "$iface" != 'vhost0' ]]; then
        echo "WARNING: First control node isn't accessible via vhost0 (or via interface that vhost0 is based on). It's valid for gateway mode and invalid for normal mode."
    fi
    if (( ${#nodes} > 1 )); then
        for node in ${nodes[@]} ; do
            local resolved_ip=$(resolve_host_ip $node)
            local cur_iface=$(get_gateway_nic_for_ip $resolved_ip)
            if [[ "$iface" != "$cur_iface" ]]; then
                echo "ERROR: Control node $node is accessible via different interface ($cur_iface) than first control node ${nodes[0]} ($iface)."
                echo "ERROR: Please define CONTROL_NODES list correctly."
                return 1
            fi
        done
    fi

    return 0
}

function ensure_host_resolv_conf() {
    local path='/etc/resolv.conf'
    local host_path="/host${path}"
    if [[ -e $path && -e $host_path  ]] && ! diff -U 3 $host_path $path > /dev/null 2>&1 ; then
        local container_content=$(cat $path)
        echo -e "INFO: $path:\n${container_content}"
        echo -e "INFO: $host_path:\n$(cat $host_path)"
        if [ -n "$container_content" ] ; then
            echo "INFO: sync $path to $host_path"
            cp -f $path $host_path
        fi
    fi
}

function dbg_trace_agent_vers() {
    local agent_ver=$BUILD_VERSION
    local loaded_vrouter_ver=$(cat /sys/module/vrouter/version)
    local available_vrouter_ver=$(modinfo -F version  vrouter)
    echo "INFO: versions: agent=$agent_ver, loaded_vrouter=$loaded_vrouter_ver, available_vrouter=$available_vrouter_ver"
}

function check_vhost0() {
    if [[ -z "$L3MH_CIDR" ]]; then
        [ -n "$(get_cidr_for_nic vhost0)" ] || return 1
        return
    fi

    ip link sh dev vhost0 >/dev/null 2>&1 || return 1
}

function init_vhost0() {
    # check vhost0
    if check_vhost0 ; then
        echo "INFO: vhost0 is already up"
        dbg_trace_agent_vers
        ensure_host_resolv_conf
        return 0
    fi

    declare phys_int phys_int_mac addrs bind_type bind_int mtu routes
    if ! is_dpdk ; then
        # NIC case
        IFS=' ' read -r phys_int phys_int_mac <<< $(get_physical_nic_and_mac)
        if [ -z "$BIND_INT" ] ; then
            # read from phys dev in non OSP case only
            addrs=$(get_addrs_for_nic $phys_int)
            mtu=$(get_iface_mtu $phys_int)
            routes=$(get_dev_routes $phys_int)
        fi
        echo "INFO: creating vhost0 for nic mode: nic: $phys_int, mac=$phys_int_mac"
        if ! create_vhost0 $phys_int $phys_int_mac ; then
            dbg_trace_agent_vers
            return 1
        fi
        bind_type='kernel'
        bind_int=$phys_int
    else
        # DPDK case
        if ! wait_dpdk_start ; then
            return 1
        fi
        local binding_data_dir='/var/run/vrouter'
        if [ ! -f "$binding_data_dir/nic" ] ; then
            echo "ERROR: there is not binding runtime information"
            return 1
        fi
        phys_int=`cat $binding_data_dir/nic`
        phys_int_mac=`cat $binding_data_dir/${phys_int}_mac`
        local pci_address=`cat $binding_data_dir/${phys_int}_pci`
        # TODO: This part of config is needed for vif tool to work,
        # later full config will be written.
        # Maybe rework somehow config pathching..
        prepare_vif_config $AGENT_MODE
        addrs=`cat $binding_data_dir/${phys_int}_ip_addresses`
        mtu=`cat $binding_data_dir/${phys_int}_mtu`
        routes=`cat $binding_data_dir/${phys_int}_routes`
        echo "INFO: creating vhost0 for dpdk mode: nic: $phys_int, mac=$phys_int_mac"
        if ! create_vhost0_dpdk $phys_int $phys_int_mac ; then
            return 1
        fi
        bind_type='dpdk'
        bind_int=$pci_address
    fi

    local ret=0
    # TODO: check that ID is sourced from /etc/os-release
    # TODO: check that rhel 8 and above supports network scripts
    if [[ "$ID" == 'rhel' ]] && [[ -e /etc/sysconfig/network-scripts/ifcfg-${phys_int} || \
        -e /etc/sysconfig/network-scripts/contrail.org.ifcfg-${phys_int} || \
        -e /etc/sysconfig/network-scripts/ifcfg-vhost0 ]]; then
        echo "INFO: creating ifcfg-vhost0 and initialize it via ifup"
        if ! is_dpdk ; then
            ifdown ${phys_int}
            kill_dhcp_clients ${phys_int}
        fi
        if [ -z "$BIND_INT" ] ; then
            # Patch if it is not the case of OSP+DPDK (BIND_INT is set if
            # dpdk container is started by ifup script, vhost0 is initialized here
            # and ifcfg files are already prepared correctly by os-net-collect)
            prepare_ifcfg $phys_int $bind_type $bind_int || true
        fi
        if ! is_dpdk ; then
            ifup ${phys_int} || { echo "ERROR: failed to ifup $phys_int." && ret=1; }
        fi
        ip link set dev vhost0 down
        ifup vhost0 || { echo "ERROR: failed to ifup vhost0." && ret=1; }
        [ -n "$mtu" ] && check_physical_mtu ${mtu} ${phys_int}
    else
        echo "INFO: there is no ifcfg-$phys_int and ifcfg-vhost0, so initialize vhost0 manually"
        if ! is_dpdk ; then
            # TODO: switch off dhcp on phys_int permanently
            kill_dhcp_clients ${phys_int}
        fi
        echo "INFO: Changing physical interface to vhost in ip table"
        echo "$addrs" | while IFS= read -r line ; do
            if ! is_dpdk ; then
                local addr_to_del=`echo $line | cut -d ' ' -f 1`
                ip address delete $addr_to_del dev $phys_int || { echo "ERROR: failed to del $addr_to_del from ${phys_int}." && ret=1; }
            fi
            local addr_to_add=`echo $line | sed 's/brd/broadcast/'`
            ip address add $addr_to_add dev vhost0 || { echo "ERROR: failed to add address $addr_to_add to vhost0." && ret=1; }
        done
        if [[ -n "$mtu" ]] ; then
            echo "INFO: set mtu"
            ip link set dev vhost0 mtu $mtu
        fi
        [ -n "$mtu" ] && check_physical_mtu ${mtu} ${phys_int}
        set_dev_routes vhost0 "$routes"
    fi
    # Remove all routes from phys iface if any.
    # One case is centos: it may assign 192.254.0.0/16 to ethX as a Zeroconf route.
    # (/etc/sysconfig/network-scripts/ifup-eth)
    if ! is_dpdk ; then
        local _phys_int_routes=$(get_dev_routes $phys_int)
        del_dev_routes ${phys_int} "$_phys_int_routes"
    fi

    [[ $ret == 0 ]] && ensure_host_resolv_conf
    dbg_trace_agent_vers
    return $ret
}

function init_vhost0_l3mh() {
    local vrouter_mac="$(get_iface_mac vhost0)"
    if [[ "$vrouter_mac" == "$L3MH_VRRP_MAC" ]] ; then
        echo "INFO: vhost0 is already up"
        dbg_trace_agent_vers
        ensure_host_resolv_conf
        return 0
    fi

    declare phys_int_mac_arr
    local phys_int_arr mtu _mtu i bind_type
    local binding_data_dir='/var/run/vrouter'
    if ! is_dpdk ; then
        bind_type='kernel'
        local control_node_ip=$(resolve_1st_control_node_ip)
        phys_int_arr=( $(l3mh_nics $control_node_ip) )
        if [[ -z "${phys_int_arr[@]}" ]]; then
            echo "ERROR: Physical NIC-s couldn't be derived from routing to control node. Please check routes."
            exit 1
        fi
        mtu=$(get_iface_mtu ${phys_int_arr[0]})
    else
        bind_type='dpdk'
        phys_int_arr=( $(cat ${binding_data_dir}/nic) )
        mtu=$(cat ${binding_data_dir}/${phys_int_arr[0]}_mtu)
        prepare_vif_config $AGENT_MODE
    fi
    i=${#phys_int_arr[@]}
    local ifcfg_files=1
    for ((i--;i>=0;i--)); do
        local phys_int=${phys_int_arr[$i]}
        phys_int_mac_arr=( $phys_int_mac_arr $(get_iface_mac $phys_int) )
        if ! is_dpdk ; then
            _mtu=$(get_iface_mtu $phys_int)
        else
            _mtu=$(cat ${binding_data_dir}/${phys_int}_mtu)
        fi
        if [[ "$mtu" != "$_mtu" ]]; then
            echo "ERROR: MTU(=$_mtu) for interface $phys_int != MTU(=$mtu) of interface ${phys_int_arr[0]}"
            exit 1
        fi
        if [[ ! -e /etc/sysconfig/network-scripts/ifcfg-${phys_int} && \
            ! -e /etc/sysconfig/network-scripts/contrail.org.ifcfg-${phys_int} ]]; then
            ifcfg_files=0
        fi
    done

    if ! is_dpdk ; then
        echo "INFO: creating vhost0 for L3MH mode. nics: ${phys_int_arr[@]}, macs: ${phys_int_mac_arr[@]}"
        if ! create_vhost0 $(echo "${phys_int_arr[@]}" | tr ' ' ',') $(echo "${phys_int_mac_arr[@]}" | tr ' ' ',') $L3MH_VRRP_MAC ; then
            dbg_trace_agent_vers
            return 1
        fi
    else
        echo "INFO: creating vhost0 for L3MH-DPDK mode. nics: ${phys_int_arr[@]}"
        if ! create_vhost0_l3mh_dpdk; then
            dbg_trace_agent_vers
            return 1
        fi
    fi

    local ret=0
    if [[ $ifcfg_files == 1 || -e /etc/sysconfig/network-scripts/ifcfg-vhost0 ]]; then
        echo "INFO: creating ifcfg-vhost0 and initialize it via ifup"
        if [ -z "$BIND_INT" ] ; then
            prepare_ifcfg_l3mh $(echo ${phys_int_arr[@]} | tr ' ' ',') $bind_type $mtu || true
        fi
        ip link set dev vhost0 down
        ifup vhost0 || { echo "ERROR: failed to ifup vhost0." && ret=1; }
    else
        echo "INFO: there is no ifcfg for ${phys_int_arr[@]} and ifcfg-vhost0, so initialize vhost0 manually"
        if [[ -n "$mtu" ]] ; then
            echo "INFO: set mtu"
            ip link set dev vhost0 mtu $mtu
        fi
    fi

    if is_dpdk ; then
        l3mh_dpdk_create_interfaces_and_routes ${phys_int_arr[@]} || ret=1;
    fi

    [[ $ret == 0 ]] && ensure_host_resolv_conf
    dbg_trace_agent_vers
    return $ret
}

function init_sriov() {
    # check whether sriov enabled
    if [[ -z "$SRIOV_PHYSICAL_INTERFACE" && -z "$SRIOV_VF" ]] ; then
        echo "INFO: sriov parameters are not provided"
        return
    fi

    local sriov_physical_interfaces=( $(echo $SRIOV_PHYSICAL_INTERFACE | tr ',' ' ') )
    local sriov_vfs=( $(echo $SRIOV_VF | tr ',' ' ') )

    if [[ -z "$SRIOV_PHYSICAL_INTERFACE" || -z "$SRIOV_VF"
        || ${#sriov_physical_interfaces[@]} != ${#sriov_vfs[@]} ]] ; then
        echo "ERROR: sriov parameters are not correct"
        exit -1
    fi
    echo "INFO: SRIOV Enabled"
    load_kernel_module ${SRIOV_VFIO_DRIVER:-'vfio'}
    local sriov_numvfs=""
    local i=0
    for i in ${!sriov_vfs[@]} ; do
        sriov_numvfs="/sys/class/net/${sriov_physical_interfaces[$i]}/device/sriov_numvfs"
        if [[ -f "$sriov_numvfs" ]] ; then
            echo "${sriov_vfs[$i]}" > $sriov_numvfs
        fi
    done
}

function cleanup_lbaas_netns_config() {
    for netns in `ip netns 2>/dev/null | awk '/^vrouter-/{print $1}'`;do
        ip netns delete $netns
    done
    rm -rf /var/lib/contrail/loadbalancer/*
}

function cleanup_contrail_cni_config() {
    rm -f /opt/cni/bin/contrail-k8s-cni
    rm -f /etc/cni/net.d/10-contrail.conf
}

# generic remove vhost functionality
function remove_vhost0() {
    if is_dpdk ; then
        # There is nothing to do in agent container for dpdk case
        # the interface is handled by dpdk container
        echo "INFO: removing vhost0 is skipped for dpdk"
        return
    fi

    if [ "$CLOUD_ORCHESTRATOR" == "kubernetes" ] && [ -n "$VROUTER_GATEWAY" ]; then
        echo "INFO: delete k8s pod cidr route"
        del_k8s_pod_cidr_route
    fi

    echo "INFO: removing vhost0"
    declare phys_int phys_int_mac restore_ip_cmd routes
    IFS=' ' read -r phys_int phys_int_mac <<< $(get_physical_nic_and_mac)
    restore_ip_cmd=$(gen_ip_addr_add_cmd vhost0 $phys_int)
    routes=$(get_dev_routes vhost0)
    del_dev_routes vhost0 "$routes"
    remove_vhost0_kernel || { echo "ERROR: failed to remove vhost0" && return 1; }
    restore_phys_int $phys_int "$restore_ip_cmd" "$routes"
}

# Modify/Deletes files created by agent container
function cleanup_vrouter_agent_files() {
    # remove config file
    rm -rf /etc/contrail/contrail-vrouter-agent.conf
}

function is_process_dead() {
    local pid=$1
    if [ -n "$pid" ] && kill -0 $pid >/dev/null 2>&1 ; then
        return 1
    fi
}

# terminate vrouter agent process
function term_process() {
    local pid=$1
    if is_process_dead $pid ; then
        return
    fi
    echo "INFO: terminate process $pid"
    kill $pid
    if wait_cmd_success "is_process_dead $pid" 3 5 ; then
        return
    fi
    echo "INFO: kill process $pid"
    kill -KILL $pid &>/dev/null
    wait_cmd_success "is_process_dead $pid" 3 5
}

# send quit signal to root process
function quit_root_process() {
    local mypid=$(cat /my.pid)
    [ -n "$mypid" ] || mypid=1
    kill -QUIT $mypid
}

# this check is required for ensuring
# dhclp clients for vhost0 is running
# for the dhcp lease renewal
function check_vhost0_dhcp_clients() {
    local pids=$(ps -A -o pid,cmd|grep 'vhost-dhcp\|vhost0' | grep -v grep | awk '{print $1}')
    echo $pids
}

# sleeping for 3 seconds is more than sufficient for the job and connectivity
# reason for the sleeps here are for the DHCP response and populting the lease file
# and also for making sure the arp table is updated with the mac of the GW
function launch_dhcp_clients() {
    mkdir -p /var/lib/dhcp
    # Update /dhclient-vhost0.conf with the system /etc/dhcp/dhclient.conf
    cat /etc/dhcp/dhclient.conf >> /dhclient-vhost0.conf
    dhclient -v -sf /etc/dhcp/dhclient-script -cf /dhclient-vhost0.conf -pf /run/dhclient.vhost0.pid -lf /var/lib/dhcp/dhclient.vhost0.leases -I vhost0 2>&1 </dev/null & disown -h "$!"
    sleep 3
}

function check_and_launch_dhcp_clients() {
    declare phys_int phys_int_mac
    IFS=' ' read -r phys_int phys_int_mac <<< $(get_physical_nic_and_mac)
    if launch_dhcp_clients ; then
       kill_dhcp_clients $phys_int
       ip addr flush $phys_int
       ensure_host_resolv_conf
    else
        echo "WARNING: dhcp clients not running for vhost0. If this is not static configuration, connectivity will be lost"
    fi
}

function add_k8s_pod_cidr_route() {
    local pod_cidr=${KUBERNETES_POD_SUBNETS:-"10.32.0.0/12"}
    local via_opts=""
    if [[ -z "$L3MH_CIDR" ]]; then
        via_opts="via $VROUTER_GATEWAY"
    fi
    ip route add $pod_cidr $via_opts dev vhost0 || ip route replace $pod_cidr $via_opts dev vhost0
}

function del_k8s_pod_cidr_route() {
    local pod_cidr=${KUBERNETES_POD_SUBNETS:-"10.32.0.0/12"}
    local via_opts=""
    if [[ -z "$L3MH_CIDR" ]]; then
        via_opts="via $VROUTER_GATEWAY"
    fi
    ip route del $pod_cidr $via_opts dev vhost0 || true
}

function mask2cidr() {
  local nbits=0
  local IFS=.
  for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
  done
  echo "$nbits"
}

function check_physical_mtu() {
    # In case of DHCP, vhost0 takes over the DHCP and gets set with the
    # MTU as provided by the DHCP interface MTU option. However the physical
    # goes to the default MTU as it is not running DHCP anymore
    # to avoid descrepancies that leads to a lot of issues, it is best to
    # ensure the physical interface is also set to the same MTU as it was.
    local mtu=$1
    local phys_int=$2
    local mtu_after_vhost=$(cat "/sys/class/net/${phys_int}/mtu")
    if [[ "$mtu_after_vhost" != "$mtu" ]] ; then
       echo "INFO: reset MTU of $phys_int"
       ip link set dev $phys_int mtu $mtu
    fi
}

function set_qos() {
    local interface_list mode policy slaves pci_addresses bond_numa
    if [[ -n "${PRIORITY_ID}" ]] || [[ -n "${QOS_QUEUE_ID}" ]]; then
        if is_dpdk ; then
            echo "INFO: Qos provisioning not supported for dpdk vrouter. Skipping."
        else
            interface_list="${PHYS_INT}"
            if is_bonding ${PHYS_INT} ; then
                IFS=' ' read -r mode policy slaves pci_addresses bond_numa <<< $(get_bonding_parameters $PHYS_INT)
                interface_list="${slaves//,/ }"
            fi
            /opt/contrail/utils/qosmap.py --interface_list ${interface_list}
        fi
    fi
}

function ip_in_cidr() {
    local ip=$1
    local cidr=$2

    local ip_parts=( $(echo $ip | tr '.' ' ') )
    local ip_addr=$(( ip_parts[0]*(2**24) + ip_parts[1]*(2**16) + ip_parts[2]*(2**8) + ip_parts[3] ))
    local cidr_parts=( $(echo $cidr | tr '.' ' ' | tr '/' ' ') )
    local cidr_start=$(( cidr_parts[0]*(2**24) + cidr_parts[1]*(2**16) + cidr_parts[2]*(2**8) + cidr_parts[3] ))
    local cidr_end=$(( cidr_start + 2**(32-cidr_parts[4]) ))
    if (( cidr_start <= ip_addr )) && (( ip_addr < cidr_end )) ; then
        return 0
    fi
    return 1
}

function eval_l3mh_loopback_ip() {
    if [[ -z "$L3MH_CIDR" ]]; then
        return
    fi
    # ip tool shows additional loopback interfaces
    local ip
    for ip in $(ip addr | awk '/inet /{print $2}' | cut -d '/' -f 1 ) ; do
        if ip_in_cidr $ip $L3MH_CIDR ; then
            echo "$ip"
            return
        fi
    done
}
