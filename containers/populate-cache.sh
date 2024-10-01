#!/bin/bash -e

# here we have ALL versions cause master branch is used to initialise cache for all branches

if ! which wget; then
   echo "ERROR: wget is not found. please install it. exit"
   exit 1
fi

CACHE_DIR=${CACHE_DIR:-'/tmp/cache'}

mkdir -p $CACHE_DIR || true
cd $CACHE_DIR

wget -nv -t3 -P containernetworking/cni/releases/download/v0.3.0 https://github.com/containernetworking/cni/releases/download/v0.3.0/cni-v0.3.0.tgz
wget -nv -t3 -P opensdn-io/tf-third-party-cache/raw/master/tshark https://github.com/opensdn-io/tf-third-party-cache/raw/master/tshark/tshark3_2.tar.bz2
wget -nv -t3 -P dnsmasq  http://www.thekelleys.org.uk/dnsmasq/dnsmasq-2.80.tar.xz

wget -nv -t3 -P rabbitmq/erlang/packages/el/7/erlang-21.3.8.21-1.el7.x86_64.rpm https://packagecloud.io/rabbitmq/erlang/packages/el/7/erlang-21.3.8.21-1.el7.x86_64.rpm/download.rpm
wget -nv -t3 -P rabbitmq/rabbitmq-server/packages/el/7/rabbitmq-server-3.7.20-1.el7.noarch.rpm https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/7/rabbitmq-server-3.7.20-1.el7.noarch.rpm/download.rpm
# from 21.4
wget -nv -t3 -P rabbitmq/erlang/packages/el/8/erlang-21.3.8.21-1.el8.x86_64.rpm https://packagecloud.io/rabbitmq/erlang/packages/el/8/erlang-21.3.8.21-1.el8.x86_64.rpm/download.rpm
wget -nv -t3 -P rabbitmq/rabbitmq-server/packages/el/7/rabbitmq-server-3.7.28-1.el7.noarch.rpm https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/7/rabbitmq-server-3.7.28-1.el7.noarch.rpm/download.rpm
wget -nv -t3 -P rabbitmq/rabbitmq-server/packages/el/8/rabbitmq-server-3.7.28-1.el8.noarch.rpm https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/8/rabbitmq-server-3.7.28-1.el8.noarch.rpm/download.rpm
# for ubi8 rabbit 3.10
wget -nv -t3 -P rabbitmq/rabbitmq-server/packages/el/8/rabbitmq-server-3.10.7-1.el8.noarch.rpm https://packagecloud.io/rabbitmq/rabbitmq-server/packages/el/8/rabbitmq-server-3.10.7-1.el8.noarch.rpm/download.rpm
wget -nv -t3 -P rabbitmq/erlang/packages/el/8/erlang-25.0.4-1.el8.x86_64.rpm https://packagecloud.io/rabbitmq/erlang/packages/el/8/erlang-25.0.4-1.el8.x86_64.rpm/download.rpm

wget -nv -t3 -P pip/2.7 https://bootstrap.pypa.io/pip/2.7/get-pip.py

wget -nv -t3 -P dist/cassandra/3.11.3 https://archive.apache.org/dist/cassandra/3.11.3/apache-cassandra-3.11.3-bin.tar.gz

# up to 2011.L1
wget -nv -t3 -P dist/zookeeper/zookeeper-3.6.1 https://archive.apache.org/dist/zookeeper/zookeeper-3.6.1/apache-zookeeper-3.6.1-bin.tar.gz
# from 2011.L2, 21.3
wget -nv -t3 -P dist/zookeeper/zookeeper-3.6.3 https://archive.apache.org/dist/zookeeper/zookeeper-3.6.3/apache-zookeeper-3.6.3-bin.tar.gz
wget -nv -t3 -P dist/zookeeper/zookeeper-3.7.0 https://archive.apache.org/dist/zookeeper/zookeeper-3.7.0/apache-zookeeper-3.7.0-bin.tar.gz
# from 2011.L5
wget -nv -t3 -P dist/zookeeper/zookeeper-3.7.1 https://archive.apache.org/dist/zookeeper/zookeeper-3.7.1/apache-zookeeper-3.7.1-bin.tar.gz

# up to 2011.L1
wget -nv -t3 -P opensdn-io/tf-third-party-cache/blob/master/kafka https://github.com/opensdn-io/tf-third-party-cache/blob/master/kafka/kafka_2.11-2.3.1.tgz?raw=true
# from 2011.L2, 21.3
# kafka 2.6.2 was moved to archive
#wget -nv -t3 -P apache/kafka/2.6.2 https://mirror.linux-ia64.org/apache/kafka/2.6.2/kafka_2.12-2.6.2.tgz
wget -nv -t3 -P dist/kafka/2.6.2 https://archive.apache.org/dist/kafka/2.6.2/kafka_2.12-2.6.2.tgz
wget -nv -t3 -P dist/kafka/2.6.3 https://archive.apache.org/dist/kafka/2.6.3/kafka_2.12-2.6.3.tgz

wget -nv -t3 -P opensdn-io/tf-third-party-cache/blob/master/redis https://github.com/opensdn-io/tf-third-party-cache/blob/master/redis/redis40u-4.0.14-2.el7.ius.x86_64.rpm?raw=true
# from 2011.L3, 21.3
wget -nv -t3 -P opensdn-io/tf-third-party-cache/blob/master/redis https://github.com/opensdn-io/tf-third-party-cache/blob/master/redis/redis-6.0.15-1.el7.remi.x86_64.rpm?raw=true

wget -nv -t3 -P Juniper/ansible-junos-stdlib/archive https://github.com/Juniper/ansible-junos-stdlib/archive/2.4.2.tar.gz

# Access denied
# wget -nv -t3 -P 30590/eng https://downloadmirror.intel.com/30590/eng/800%20series%20comms%20binary%20package%201.3.30.0.zip

wget -nv -t3 -P linux/centos/7/x86_64/stable/Packages https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.4.12-3.1.el7.x86_64.rpm
#from 2011.L5
wget -nv -t3 -P linux/centos/7/x86_64/stable/Packages https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.6.7-3.1.el7.x86_64.rpm

wget -nv -t3 -P pub/archive/epel/8.4/Everything/x86_64/Packages/s https://archives.fedoraproject.org/pub/archive/epel/8.4/Everything/x86_64/Packages/s/sshpass-1.06-9.el8.x86_64.rpm

wget -nv -t3 -P maven2/io/netty/netty-all/4.1.39.Final https://repo1.maven.org/maven2/io/netty/netty-all/4.1.39.Final/netty-all-4.1.39.Final.jar
wget -nv -t3 -P maven2/ch/qos/logback/logback-classic/1.2.9 https://repo1.maven.org/maven2/ch/qos/logback/logback-classic/1.2.9/logback-classic-1.2.9.jar
wget -nv -t3 -P maven2/ch/qos/logback/logback-core/1.2.9 https://repo1.maven.org/maven2/ch/qos/logback/logback-core/1.2.9/logback-core-1.2.9.jar

wget -nv -t3 -P centos/7/os/x86_64/Packages http://vault.centos.org/centos/7/os/x86_64/Packages/ntpdate-4.2.6p5-29.el7.centos.2.x86_64.rpm
wget -nv -t3 -P centos/7/os/x86_64/Packages http://vault.centos.org/centos/7/os/x86_64/Packages/ntp-4.2.6p5-29.el7.centos.2.x86_64.rpm

wget -nv -t3 -P opensdn-io/tf-third-party-cache/blob/master/libthrift https://github.com/opensdn-io/tf-third-party-cache/blob/master/libthrift/libthrift-0.13.0.jar?raw=true

wget -nv -t3 -P thelastpickle/cassandra-reaper/releases/download/3.2.1 https://github.com/thelastpickle/cassandra-reaper/releases/download/3.2.1/reaper-3.2.1-1.x86_64.rpm

# get kernel packages for rocky
# rocky9 kernel for 9.0
wget -nv -t3 -P vault/rocky/9.0/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-70.30.1.el9_0.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.0/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-70.30.1.el9_0.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.0/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.0/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-70.30.1.el9_0.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.0/AppStream/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.0/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-70.30.1.el9_0.x86_64.rpm

# rocky9 kernel for 9.1
wget -nv -t3 -P vault/rocky/9.1/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-162.23.1.el9_1.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.1/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-162.23.1.el9_1.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.1/BaseOS/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.1/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-162.23.1.el9_1.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.1/AppStream/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.1/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-162.23.1.el9_1.x86_64.rpm

# rocky9 kernel for 9.2
wget -nv -t3 -P vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/ https://dl.rockylinux.org/vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-5.14.0-284.30.1.el9_2.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/ https://dl.rockylinux.org/vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-core-5.14.0-284.30.1.el9_2.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/ https://dl.rockylinux.org/vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-modules-5.14.0-284.30.1.el9_2.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/ https://dl.rockylinux.org/vault/rocky/9.2/BaseOS/x86_64/os/Packages/k/kernel-modules-core-5.14.0-284.30.1.el9_2.x86_64.rpm
wget -nv -t3 -P vault/rocky/9.2/AppStream/x86_64/os/Packages/k https://dl.rockylinux.org/vault/rocky/9.2/AppStream/x86_64/os/Packages/k/kernel-devel-5.14.0-284.30.1.el9_2.x86_64.rpm

# rocky9 kernel for 9.3
wget -nv -t3 -P kojifiles/packages/kernel/5.14.0/362.el9s/x86_64 https://cbs.centos.org/kojifiles/packages/kernel/5.14.0/362.el9s/x86_64/kernel-5.14.0-362.el9s.x86_64.rpm
wget -nv -t3 -P kojifiles/packages/kernel/5.14.0/362.el9s/x86_64 https://cbs.centos.org/kojifiles/packages/kernel/5.14.0/362.el9s/x86_64/kernel-core-5.14.0-362.el9s.x86_64.rpm
wget -nv -t3 -P kojifiles/packages/kernel/5.14.0/362.el9s/x86_64 https://cbs.centos.org/kojifiles/packages/kernel/5.14.0/362.el9s/x86_64/kernel-modules-5.14.0-362.el9s.x86_64.rpm
wget -nv -t3 -P kojifiles/packages/kernel/5.14.0/362.el9s/x86_64 https://cbs.centos.org/kojifiles/packages/kernel/5.14.0/362.el9s/x86_64/kernel-modules-core-5.14.0-362.el9s.x86_64.rpm
wget -nv -t3 -P kojifiles/packages/kernel/5.14.0/362.el9s/x86_64 https://cbs.centos.org/kojifiles/packages/kernel/5.14.0/362.el9s/x86_64/kernel-devel-5.14.0-362.el9s.x86_64.rpm
