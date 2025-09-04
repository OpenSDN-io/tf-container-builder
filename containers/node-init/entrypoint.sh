#!/bin/bash

# to save output logs to correct place
export SERVICE_NAME=node-init

ret=0

/sysctl-init.sh || ret=1
echo "INFO: sysctl-init ret code = $ret"

/opensdn-status-init.sh || ret=1
echo "INFO: opensdn-status-init ret code = $ret"

/opensdn-tools-init.sh || ret=1
echo "INFO: opensdn-tools-init ret code = $ret"

/certs-init.sh || ret=1
echo "INFO: certs-init ret code = $ret"

/files-init.sh || ret=1
echo "INFO: files-init ret code = $ret"

/firewall.sh || ret=1
echo "INFO: firewall ret code = $ret"

exit $ret
