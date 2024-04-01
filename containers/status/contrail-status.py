#!/usr/bin/python

# to avoid warning and recursive calls during imporint ssl
# See https://github.com/gevent/gevent/issues/1016
import gevent.monkey
gevent.monkey.patch_all()

import logging
import operator
import optparse
import os
import time
import socket
import struct
import subprocess
import warnings
import json

import docker
from lxml import etree
import requests
from sandesh_common.vns import constants as vns_constants
import six
from urllib3.exceptions import SubjectAltNameWarning
import yaml
from nodemgr.common import utils as utils
from nodemgr.common import cri_containers as cri
from nodemgr.common import containerd_containers as ctr

warnings.filterwarnings('ignore', category=SubjectAltNameWarning)
warnings.filterwarnings('ignore', ".*SNIMissingWarning.*")
warnings.filterwarnings('ignore', ".*InsecurePlatformWarning.*")
warnings.filterwarnings('ignore', ".*SubjectAltNameWarning.*")


CONTRAIL_SERVICES_TO_SANDESH_SVC = {
    'vrouter': {
        'nodemgr': 'contrail-vrouter-nodemgr',
        'agent': 'contrail-vrouter-agent',
    },
    'control': {
        'nodemgr': 'contrail-control-nodemgr',
        'control': 'contrail-control',
        'named': 'contrail-named',
        'dns': 'contrail-dns',
    },
    'config': {
        'nodemgr': 'contrail-config-nodemgr',
        'api': 'contrail-api',
        'schema': 'contrail-schema',
        'svc-monitor': 'contrail-svc-monitor',
        'device-manager': 'contrail-device-manager',
    },
    'config-database': {
        'nodemgr': 'contrail-config-database-nodemgr',
        'cassandra': None,
        'zookeeper': None,
        'rabbitmq': None,
    },
    'analytics': {
        'nodemgr': 'contrail-analytics-nodemgr',
        'api': 'contrail-analytics-api',
        'collector': 'contrail-collector',
    },
    'analytics-alarm': {
        'nodemgr': 'contrail-analytics-alarm-nodemgr',
        'alarm-gen': 'contrail-alarm-gen',
        'kafka': None,
    },
    'analytics-snmp': {
        'nodemgr': 'contrail-analytics-snmp-nodemgr',
        'snmp-collector': 'contrail-snmp-collector',
        'topology': 'contrail-topology',
    },
    'kubernetes': {
        'kube-manager': 'contrail-kube-manager',
    },
    'database': {
        'nodemgr': 'contrail-database-nodemgr',
        'query-engine': 'contrail-query-engine',
        'cassandra': None,
    },
    'webui': {
        'web': None,
        'job': None,
    },
    'toragent': {
        'tor-agent': 'contrail-tor-agent',
    }
}

SHARED_SERVICES = [
    'contrail-external-redis',
    'contrail-external-stunnel',
    'contrail-external-rsyslogd',
]

INDEXED_SERVICES = [
    'tor-agent',
]

CONTRAIL_SERVICES_TO_INTROSPECT_VAR = {
    'contrail-vrouter-agent': 'VROUTER_AGENT_INTROSPECT_PORT',
    'contrail-tor-agent': 'TOR_HTTP_SERVER_PORT',
    'contrail-dns': 'DNS_INTROSPECT_PORT',
    'contrail-control': 'CONTROL_INTROSPECT_PORT',
    'contrail-topology': 'TOPOLOGY_INTROSPECT_PORT',
    'contrail-snmp-collector': 'SNMPCOLLECTOR_INTROSPECT_PORT',
    'contrail-alarm-gen': 'ALARMGEN_INTROSPECT_PORT',
    'contrail-collector': 'COLLECTOR_INTROSPECT_PORT',
    'contrail-query-engine': 'QUERYENGINE_INTROSPECT_PORT',
    'contrail-analytics-api': 'ANALYTICS_API_INTROSPECT_PORT',
    'contrail-api': 'CONFIG_API_INTROSPECT_PORT',
}


class DockerContainersInterface:
    def __init__(self):
        self._client = docker.from_env()
        if hasattr(self._client, 'api'):
            self._client = self._client.api

    def list(self, filter_):
        f = {'label': [filter_]}
        return self._client.containers(all=True, filters=f)

    def inspect(self, id_):
        try:
            return self._client.inspect_container(id_)
        except docker.errors.APIError:
            logging.exception('docker')
            return None


class PodmanContainersInterface:
    def _execute(self, arguments_, timeout_=10):
        a = ["podman"]
        a.extend(arguments_)
        p = subprocess.Popen(a, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            o, e = p.communicate(timeout_)
        except subprocess.TimeoutExpired:
            p.kill()
            o, e = p.communicate()
        p.wait()
        if e:
            logging.critical(e)

        return (p.returncode, o)

    def _parse_json(self, arguments_):
        a = []
        a.extend(arguments_)
        a.extend(["--format", "json"])
        c, o = self._execute(a)
        if 0 != c:
            # NB. there is nothing to parse
            return (c, None)

        try:
            return (c, json.loads(o))
        except Exception:
            logging.exception('json parsing')
            return (c, None)

    def _decorate(self, container_):
        if container_:
            if 'ID' in container_:
                container_['Id'] = container_['ID']
            if 'State' in container_:
                s = container_['State']
                # podman in ubi8 contains state directly as string
                if isinstance(s, int):
                    states_ = [
                        'unknown', 'configured', 'created',
                        'running', 'stopped', 'paused', 'exited',
                        'removing'
                    ]
                    container_['State'] = states_[s]
        return container_

    def list(self, filter_):
        _, output = self._parse_json([
            "ps", "-a", "--filter",
            '"label={0}"'.format(filter_)])
        if output:
            for i in output:
                self._decorate(i)

        return output

    def inspect(self, id_):
        _, output = self._parse_json(["inspect", id_])
        if output and len(output) > 0:
            return output[0]

        return None


class ContainerdContainersInterface:
    def __init__(self, containerd_):
        self._containerd = containerd_

    def list(self, filter_):
        x = self._containerd.list(True)
        y = [i for i in x if filter_ in i['Labels']]
        # NB. openshift list doesn't contain required labels.
        # we duplicate the labels values in ct env. we use the envs
        # to perform filtering later. the list doesn't have env
        # info. let's return full list if the label filtering fails.
        return x if 0 < len(x) and len(y) == 0 else y

    def inspect(self, id_):
        return self._containerd.inspect(id_)


debug_output = False
# docker client is used in several places - just cache it at start
client = None
ssl_enabled = False

json_output = {'containers': {}, 'pods': {}, 'msgs': []}


def print_msg(msg):
    if output_format == 'text':
        print(msg)


def print_debug(str):
    if debug_output:
        print("DEBUG: " + str)


class EtreeToDict(object):
    """Converts the xml etree to dictionary/list of dictionary."""

    def __init__(self, xpath):
        self.xpath = xpath

    def _handle_list(self, elems):
        """Handles the list object in etree."""
        a_list = []
        for elem in elems.getchildren():
            rval = self._get_one(elem, a_list)
            if 'element' in rval.keys():
                a_list.append(rval['element'])
            elif 'list' in rval.keys():
                a_list.append(rval['list'])
            else:
                a_list.append(rval)

        return a_list if a_list else None

    def _get_one(self, xp, a_list=None):
        """Recrusively looks for the entry in etree and converts to dictionary.

        Returns a dictionary.
        """
        val = {}

        child = xp.getchildren()
        if not child:
            val.update({xp.tag: xp.text})
            return val

        for elem in child:
            if elem.tag == 'list':
                val.update({xp.tag: self._handle_list(elem)})
            else:
                rval = self._get_one(elem, a_list)
                if elem.tag in rval.keys():
                    val.update({elem.tag: rval[elem.tag]})
                else:
                    val.update({elem.tag: rval})
        return val

    def get_all_entry(self, path):
        """All entries in the etree is converted to the dictionary

        Returns the list of dictionary/didctionary.
        """
        xps = path.xpath(self.xpath)

        if type(xps) is not list:
            return self._get_one(xps)

        val = []
        for xp in xps:
            val.append(self._get_one(xp))
        return val

    def find_entry(self, path, match):
        """Looks for a particular entry in the etree.
        Returns the element looked for/None.
        """
        xp = path.xpath(self.xpath)
        f = filter(lambda x: x.text == match, xp)
        return f[0].text if len(f) else None


listeners = None


def fill_listeners():
    global listeners
    with open('/proc/net/tcp', 'r') as f:
        lines = f.readlines()[1:]
    if len(lines) == 0:
        return

    listeners = dict()
    default_addr = socket.getfqdn()
    for line in lines:
        items = line.split()
        # 0A is a TCP_LISTEN from net/tcp_states.h
        if len(items) < 4 or int(items[3], base=16) != 10:
            continue
        ip, port = items[1].split(":")
        ip = socket.inet_ntoa(struct.pack("<L", int(ip, base=16)))
        addr = socket.getfqdn(ip) if ip != "0.0.0.0" else default_addr
        port = str(int(port, base=16))
        # doesn't matter what address will be stored - we need any to request introspect status
        listeners[port] = addr


def get_addr_to_connect(port):
    global listeners
    if not listeners:
        fill_listeners()

    if listeners and port in listeners:
        return listeners[port]
    return socket.getfqdn()


class IntrospectUtil(object):
    def __init__(self, port, options):
        self._port = port
        self._timeout = options.timeout
        self._cacert = options.cacert if os.path.isfile(options.cacert) else False
        self._certs = (options.certfile, options.keyfile) \
            if (os.path.isfile(options.certfile) and
                os.path.isfile(options.keyfile)) else None

    def _mk_url_str(self, path, secure=False):
        proto = "https" if secure else "http"
        ip = get_addr_to_connect(self._port)
        return "%s://%s:%d/%s" % (proto, ip, self._port, path)

    def _make_request(self, path, secure):
        url = self._mk_url_str(path, secure=secure)
        if not secure:
            return requests.get(url, timeout=self._timeout)
        return requests.get(url, timeout=self._timeout,
                            verify=self._cacert, cert=self._certs)

    def _load(self, path):
        try:
            resp = self._make_request(path, ssl_enabled)
        except requests.exceptions.ConnectionError:
            resp = self._make_request(path, not ssl_enabled)
        if resp.status_code != requests.codes.ok:
            print_debug('PATH: %s : HTTP error: %s' % (path, str(resp.status_code)))
            return None

        return etree.fromstring(resp.text)

    def get_uve(self, tname):
        path = 'Snh_SandeshUVECacheReq?x=%s' % (tname)
        return self.get_data(path, tname)

    def get_data(self, path, tname):
        xpath = './/' + tname
        p = self._load(path)
        if p is not None:
            return EtreeToDict(xpath).get_all_entry(p)
        print_debug('UVE: %s : not found' % (path))
        return None


def get_http_server_port(svc_name, env, port_env_key):
    port = None
    if not port_env_key:
        port_env_key = CONTRAIL_SERVICES_TO_INTROSPECT_VAR.get(svc_name)
    if port_env_key:
        p = get_value_from_env(env, port_env_key)
        port = int(p) if p else None
    if not port:
        port = vns_constants.ServiceHttpPortMap.get(svc_name)
    if port:
        return port

    print_debug('{0}: Introspect port not found'.format(svc_name))
    return None


def get_svc_uve_status(svc_name, http_server_port, options):
    # Now check the NodeStatus UVE
    svc_introspect = IntrospectUtil(http_server_port, options)
    node_status = svc_introspect.get_uve('NodeStatus')
    if node_status is None:
        print_debug('{0}: NodeStatusUVE not found'.format(svc_name))
        return None, None
    node_status = [item for item in node_status if 'process_status' in item]
    if not len(node_status):
        print_debug('{0}: ProcessStatus not present in NodeStatusUVE'.format(svc_name))
        return None, None
    process_status_info = node_status[0]['process_status']
    if len(process_status_info) == 0:
        print_debug('{0}: Empty ProcessStatus in NodeStatusUVE'.format(svc_name))
        return None, None
    description = process_status_info[0]['description']
    for connection_info in process_status_info[0].get('connection_infos', []):
        if connection_info.get('type') == 'ToR':
            description = 'ToR:%s connection %s' % (connection_info['name'], connection_info['status'].lower())
    return process_status_info[0]['state'], description


def get_status_from_container(container):
    if container and container.get('State') == 'running':
        return 'active'
    return 'inactive'


def get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status):
    if svc_uve_status is not None:
        if svc_uve_status == 'Non-Functional':
            svc_status = 'initializing'
        elif svc_uve_status == 'connection-error':
            if svc_name in vns_constants.BackupImplementedServices:
                svc_status = 'backup'
            else:
                svc_status = 'initializing'
        elif svc_uve_status == 'connection-timeout':
            svc_status = 'timeout'
    else:
        svc_status = 'initializing'
    if svc_uve_description:
        svc_status = svc_status + ' (' + svc_uve_description + ')'
    return svc_status


def get_svc_uve_info(svc_name, container, port_env_key, options):
    svc_status = get_status_from_container(container)
    if svc_status != 'active':
        return svc_status
    # Extract UVE state only for running processes
    svc_uve_description = None
    if (svc_name not in vns_constants.NodeUVEImplementedServices and
            svc_name.rsplit('-', 1)[0] not in vns_constants.NodeUVEImplementedServices):
        return svc_status

    svc_uve_status = None
    svc_uve_description = None
    try:
        # Get the HTTP server (introspect) port for the service
        http_server_port = get_http_server_port(svc_name, container['Env'], port_env_key)
        if http_server_port:
            svc_uve_status, svc_uve_description = \
                get_svc_uve_status(svc_name, http_server_port, options)
    except (requests.Timeout, socket.timeout) as te:
        print_debug('Timeout error : %s' % (str(te)))
        svc_uve_status = "connection-timeout"
    except (requests.exceptions.ConnectionError, IOError) as e:
        print_debug('Socket Connection error : %s' % (str(e)))
        svc_uve_status = "connection-error"
    return get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status)


# predefined name as POD_SERVICE. shouldn't be changed.
def config_api(container, options):
    svc_name = CONTRAIL_SERVICES_TO_SANDESH_SVC['config']['api']

    dict_container_env = dict(item.split("=") for item in container['Env'])
    worker_count = int(dict_container_env.get('CONFIG_API_WORKER_COUNT', 1))
    svc_status_list = [None] * worker_count

    svc_status = get_status_from_container(container)
    if svc_status != 'active':
        svc_status_list = [svc_status for index in range(worker_count)]
        return svc_status_list

    # Extract UVE state only for running processes
    if (svc_name not in vns_constants.NodeUVEImplementedServices and
            svc_name.rsplit('-', 1)[0] not in vns_constants.NodeUVEImplementedServices):
        svc_status_list = [svc_status for index in range(worker_count)]
        return svc_status_list

    svc_uve_status = None
    svc_uve_description = None

    http_server_port = get_http_server_port(svc_name, container['Env'], None)
    if http_server_port:
        svc_config_introspect = IntrospectUtil(http_server_port, options)
        try:
            config_worker_uves = svc_config_introspect.get_uve('ConfigApiWorker')
        except (requests.Timeout, socket.timeout) as te:
            print_debug('Timeout error : %s' % (str(te)))
            svc_uve_status = "connection-timeout"
            return get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status)
        except (requests.exceptions.ConnectionError, IOError) as e:
            print_debug('Socket Connection error : %s' % (str(e)))
            svc_uve_status = "connection-error"
            return get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status)
        if not config_worker_uves:
            return get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status)

        worker_id = None
        for uve in config_worker_uves:
            try:
                introspect_port = int(uve.get('introspect_port'))
                worker_id = int(uve.get('worker_id'))
                svc_uve_status, svc_uve_description = \
                    get_svc_uve_status(svc_name, introspect_port, options)
            except (requests.Timeout, socket.timeout) as te:
                print_debug('Timeout error : %s' % (str(te)))
                svc_uve_status = "timeout"
            except (requests.exceptions.ConnectionError, IOError) as e:
                print_debug('Socket Connection error : %s' % (str(e)))
                svc_uve_status = "initializing"

            worker_status = get_svc_status(svc_name, svc_uve_status, svc_uve_description, svc_status)
            svc_status_list[worker_id] = worker_status

    if len(svc_status_list) == 1:
        return svc_status_list[0]
    return svc_status_list


# predefined name as POD_SERVICE. shouldn't be changed.
def contrail_pod_status(pod_name, pod_services, options):
    print_msg("== Contrail {} ==".format(pod_name))
    pod_map = CONTRAIL_SERVICES_TO_SANDESH_SVC.get(pod_name)
    if not pod_map:
        print_msg('')
        return

    for service, internal_svc_name in six.iteritems(pod_map):
        if service not in INDEXED_SERVICES:
            container = pod_services.get(service)
            status = contrail_service_status(container, pod_name, service, internal_svc_name, options)
            if isinstance(status, list):
                for index in range(len(status)):
                    service_name = "%s-%s" % (service, index)
                    print_msg("{}: {}".format(service_name, status[index]))
                    json_output['pods'].setdefault(pod_name, list()).append({service_name: status[index]})
            else:
                print_msg("{}: {}".format(service, status))
                json_output['pods'].setdefault(pod_name, list()).append({service: status})
        else:
            for srv_key in pod_services:
                if not srv_key.startswith(service):
                    continue
                container = pod_services[srv_key]
                status = contrail_service_status(container, pod_name, service, internal_svc_name, options)
                print_msg("{}: {}".format(service, status))
                json_output['pods'].setdefault(pod_name, list()).append({service: status})

    print_msg('')


def contrail_service_status(container, pod_name, service, internal_svc_name, options):
    fn_name = "{}_{}".format(pod_name, service).replace('-', '_')
    fn = globals().get(fn_name)
    if fn:
        return fn(container, options)

    if internal_svc_name:
        # TODO: pass env key for introspect port if needed
        return get_svc_uve_info(internal_svc_name, container, None, options)

    return get_status_from_container(container)


def get_value_from_env(env, key):
    if not env:
        return None
    value = next(iter(
        [i for i in env if i.startswith('%s=' % key)]), None)
    # If env value is not found return none
    return value.split('=')[1] if value else None


def get_full_env_of_container(cid):
    cnt_full = client.inspect(cid)
    return cnt_full['Config'].get('Env')


def get_containers():
    # TODO: try to reuse this logic with nodemgr

    items = dict()
    vendor_domain = os.getenv('VENDOR_DOMAIN', 'net.juniper.contrail')
    flt = vendor_domain + '.container.name'
    for cnt in client.list(flt):
        labels = cnt.get('Labels', dict())
        if not labels:
            continue
        service = labels.get(vendor_domain + '.service')
        full_env = get_full_env_of_container(cnt['Id'])
        if not service:
            service = get_value_from_env(full_env, 'SERVICE_NAME')
        if not service:
            # filter only service containers (skip *-init, contrail-status)
            continue
        pod = labels.get(vendor_domain + '.pod')
        if not pod:
            pod = get_value_from_env(full_env, 'NODE_TYPE')
        name = labels.get(vendor_domain + '.container.name')
        if not name:
            name = get_value_from_env(full_env, 'CONTAINER_NAME')

        version = labels.get('version')
        if not version:
            version = get_value_from_env(full_env, 'CONTRAIL_VERSION')

        env_hash = hash(frozenset(full_env))

        # service is not empty at this point
        key = '{}.{}'.format(pod, service) if pod else name
        if service in INDEXED_SERVICES:
            # TODO: rework the code to support issue CEM-5176 for indexed services
            # right now indexed service is implemented only in ansible-deployer and
            # exited services are not possible there.
            key += '.{}'.format(env_hash)
        item = {
            'Pod': pod if pod else '',
            'Service': service,
            'Original Name': name,
            'Original Version': version,
            'State': cnt['State'],
            'Status': cnt.get('Status', ''),
            'Id': cnt['Id'][0:12],
            'Created': cnt['Created'],
            'Env': full_env,
            'env_hash': env_hash,
        }
        if key not in items:
            items[key] = item
            continue
        if cnt['State'] != items[key]['State']:
            if cnt['State'] == 'running':
                items[key] = item
            continue
        # if both has same state - add latest.
        if cnt['Created'] > items[key]['Created']:
            items[key] = cnt

    return items


def print_containers(containers):
    # containers is a dict of dicts
    hdr = ['Pod', 'Service', 'Original Name', 'Original Version', 'State', 'Id', 'Status']
    items = list()
    items.extend([v[hdr[0]], v[hdr[1]], v[hdr[2]], v[hdr[3]], v[hdr[4]], v[hdr[5]], v[hdr[6]]]
                 for k, v in six.iteritems(containers))
    items.sort(key=operator.itemgetter(0, 1))
    items.insert(0, hdr)

    cols = [1 for _ in range(0, len(items[0]))]
    for item in items:
        for i in range(0, len(cols)):
            cl = 2 + len(item[i])
            if cols[i] < cl:
                cols[i] = cl
    for i in range(0, len(cols)):
        cols[i] = '{{:{}}}'.format(cols[i])
    for item in items:
        res = ''
        for i in range(0, len(cols)):
            res += cols[i].format(item[i])
        print_msg(res)
    print_msg('')


def craft_client():
    if utils.is_running_in_docker():
        return DockerContainersInterface()

    if not os.path.exists('/run/.containerenv'):
        # NB. CRIO is not fast enough when it comes to creating
        # the mark file after container start.
        # anyway let's try to connect to containerd first when
        # the mark is absent and if it fails because of the socket
        # absence make another attempt after the timeout to detect
        # a ct engine hoping CRIO has created the file finally.
        try:
            return ContainerdContainersInterface(
                ctr.ContainerdContainersInterface.craft_containerd_peer())
        except LookupError:
            time.sleep(3)

    if not os.path.exists('/run/.containerenv'):
        return ContainerdContainersInterface(
            ctr.ContainerdContainersInterface.craft_containerd_peer())

    try:
        return ContainerdContainersInterface(
            cri.CriContainersInterface.craft_crio_peer())
    except LookupError:
        return PodmanContainersInterface()


def parse_args():
    parser = optparse.OptionParser()
    parser.add_option('-d', '--detail', dest='detail',
                      default=False, action='store_true',
                      help="show detailed status")
    parser.add_option('-x', '--debug', dest='debug',
                      default=False, action='store_true',
                      help="show debugging information")
    parser.add_option('-t', '--timeout', dest='timeout', type="float",
                      default=5,
                      help="timeout in seconds to use for HTTP requests to services")
    parser.add_option('-k', '--keyfile', dest='keyfile', type="string",
                      default="/etc/contrail/ssl/private/server-privkey.pem",
                      help="ssl key file to use for HTTP requests to services")
    parser.add_option('-c', '--certfile', dest='certfile', type="string",
                      default="/etc/contrail/ssl/certs/server.pem",
                      help="certificate file to use for HTTP requests to services")
    parser.add_option('-a', '--cacert', dest='cacert', type="string",
                      default="/etc/contrail/ssl/certs/ca-cert.pem",
                      help="ca-certificate file to use for HTTP requests to services")
    parser.add_option('-f', '--format', dest='format', type="choice",
                      default="text", choices=("text", "json"),
                      help="Output format: shell, json")
    options, _ = parser.parse_args()
    return options


def main():
    global debug_output
    global client
    global output_format
    global ssl_enabled

    options = parse_args()
    debug_output = options.debug
    output_format = options.format
    if not debug_output:
        requests.packages.urllib3.disable_warnings()

    ssl_enabled = yaml.load(os.getenv('INTROSPECT_SSL_ENABLE', 'False'), Loader=yaml.Loader)
    if not isinstance(ssl_enabled, bool):
        ssl_enabled = False

    client = craft_client()
    containers = get_containers()
    print_containers(containers)
    json_output['containers'] = containers

    # first check and store containers dict as a tree
    fail = False
    pods = dict()
    for k, v in six.iteritems(containers):
        pod = v['Pod']
        service = v['Service']
        if service in INDEXED_SERVICES:
            service += '.{}'.format(v['env_hash'])
        # get_containers always fill service
        if pod and service:
            pods.setdefault(pod, dict())[service] = v
            continue
        if not pod and v['Original Name'] in SHARED_SERVICES:
            continue
        msg = ("WARNING: container with original name '{}' "
               "have Pod or Service empty. Pod: '{}' / Service: '{}'. "
               "Please pass NODE_TYPE with pod name to container's env".format(
                   v['Original Name'], v['Pod'], v['Service']))
        print_msg(msg)
        json_output['msgs'].append(msg)
        fail = True
    if fail:
        print_msg('')

    vrouter_driver = False
    try:
        lsmod = subprocess.Popen('lsmod', stdout=subprocess.PIPE).communicate()[0]
        if lsmod.find('vrouter') != -1:
            vrouter_driver = True
            msg = "vrouter kernel module is PRESENT"
            print_msg(msg)
            json_output['msgs'].append(msg)
    except Exception as ex:
        print_debug('lsmod FAILED: {0}'.format(ex))
    try:
        lsof = (subprocess.Popen(
            ['netstat', '-xl'], stdout=subprocess.PIPE).communicate()[0])
        if lsof.find('dpdk_netlink') != -1:
            vrouter_driver = True
            msg = "vrouter DPDK module is PRESENT"
            print_msg(msg)
            json_output['msgs'].append(msg)
    except Exception as ex:
        print_debug('lsof FAILED: {0}'.format(ex))
    if 'vrouter' in pods and not vrouter_driver:
        msg = "vrouter driver is not PRESENT but agent pod is present"
        print_msg(msg)
        json_output['msgs'].append(msg)

    for pod_name in pods:
        contrail_pod_status(pod_name, pods[pod_name], options)
    if output_format == "json":
        print(json.dumps(json_output))


if __name__ == '__main__':
    main()
