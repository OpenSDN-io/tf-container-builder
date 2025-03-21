#!/usr/bin/python3

import logging
import os
import sys

from vnc_api.vnc_api import VncApi
from vnc_api.gen.resource_client import PhysicalRouter

DEFAULT_LOG_PATH = '/var/log/contrail/dnsmasq.log'
LOGGING_FORMAT = \
    '%(asctime)s.%(msecs)03d %(name)s [%(levelname)s]:  %(message)s'
DATE_FORMAT = "%m/%d/%Y %H:%M:%S"


def _initialize_vnc():
    controller_nodes = os.environ.get('CONTROLLER_NODES', None).split(',')
    # keystone global env data
    user = os.environ.get('KEYSTONE_AUTH_ADMIN_USER', None)
    passwd = os.environ.get('KEYSTONE_AUTH_ADMIN_PASSWORD', None)
    tenant = os.environ.get('KEYSTONE_AUTH_ADMIN_TENANT', None)

    if user and passwd and tenant:
        vnc_api = VncApi(username=user,
                         password=passwd,
                         tenant_name=tenant,
                         api_server_host=controller_nodes)
    else:
        vnc_api = VncApi()

    return vnc_api


def main():
    logging.basicConfig(
        filename=DEFAULT_LOG_PATH,
        level=logging.INFO,
        format=LOGGING_FORMAT,
        datefmt=DATE_FORMAT)
    logger = logging.getLogger("dnsmasq")
    logger.setLevel(logging.INFO)
    vnc_api = _initialize_vnc()
    if sys.argv[1] == 'read':
        # read from DB mac:ip
        filters = {}
        lease = 0
        filters['physical_router_managed_state'] = "dhcp"
        for pr in vnc_api.physical_routers_list(filters=filters).get(
                'physical-routers'):
            device_obj = vnc_api.physical_router_read(
                id=pr.get('uuid'), fields=['physical_router_management_mac',
                                           'physical_router_management_ip',
                                           'physical_router_dhcp_parameters']
            )
            if device_obj.get_physical_router_dhcp_parameters():
                lease = device_obj.get_physical_router_dhcp_parameters().\
                        lease_expiry_time

            print("DNSMASQ_LEASE=%s %s %s * *" % (
                lease,
                device_obj.get_physical_router_management_mac(),
                device_obj.get_physical_router_management_ip()))
            logger.info("DNSMASQ_LEASE=%s %s %s * *" % (
                lease,
                device_obj.get_physical_router_management_mac(),
                device_obj.get_physical_router_management_ip()))
    elif sys.argv[1] == 'write':
        # write to the DB dummy PR with mac:ip
        fq_name = ['default-global-system-config', sys.argv[4]]
        physicalrouter = PhysicalRouter(
            parent_type='global-system-config',
            fq_name=fq_name,
            physical_router_management_mac=sys.argv[2],
            physical_router_management_ip=sys.argv[3],
            physical_router_managed_state='dhcp',
            physical_router_hostname=sys.argv[4],
            physical_router_dhcp_parameters={
                'lease_expiry_time': sys.argv[5]
            },
            physical_router_device_family=sys.argv[6]
        )
        try:
            pr_uuid = vnc_api.physical_router_create(physicalrouter)
        except Exception:
            logger.info(
                "Router '%s' already exists, hence updating it" % fq_name[-1]
            )
            pr_uuid = vnc_api.physical_router_update(physicalrouter)

        logger.info("DNSMASQ_LEASE_OBTAINED=%s %s %s" % (sys.argv[4],
                                                         sys.argv[2],
                                                         sys.argv[3]))
        logger.info("Router created id: %s" % pr_uuid)
    elif sys.argv[1] == 'delete':
        object_type = "physical_router"
        device_family = ""
        fq_name = ['default-global-system-config', sys.argv[2]]
        try:
            pr_uuid = vnc_api.fq_name_to_id(object_type, fq_name)
            device_obj = vnc_api.physical_router_read(
                         id=pr_uuid, fields=['physical_router_device_family']
                         )
            device_family = device_obj.get_physical_router_device_family()
            logger.info("Device Family %s", device_family)
            if "qfx5220" not in device_family:
                vnc_api.physical_router_delete(fq_name=fq_name)
        except Exception:
            logger.info("Router '%s' doesnot exist" % fq_name[-1])


if __name__ == '__main__':
    main()
