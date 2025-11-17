#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.13
export IP_ETCD_1=10.0.0.16
export IP_ETCD_2=10.0.0.18

export KRV_PORT_API=2379
export KRV_PORT_ZONGZI=2380
export KRV_HOST_PEERS=${IP_ETCD_0}:${KRV_PORT_ZONGZI},${IP_ETCD_1}:${KRV_PORT_ZONGZI},${IP_ETCD_2}:${KRV_PORT_ZONGZI}

scp -o "StrictHostKeyChecking=accept-new" krv root@${IP_ETCD_1}:/root/krv
scp -o "StrictHostKeyChecking=accept-new" krv root@${IP_ETCD_1}:

# etc-0
KRV_HOST_NAME=${IP_ETCD_0} krv

# etc-1
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/root/krv .
KRV_HOST_NAME=${IP_ETCD_1} krv

# etc-2
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/root/krv .
KRV_HOST_NAME=${IP_ETCD_2} krv

ETCDCTL_API=3 etcdctl \
--endpoints http://${IP_ETCD_0}:${KRV_PORT_API},http://${IP_ETCD_1}:${KRV_PORT_API},http://${IP_ETCD_2}:${KRV_PORT_API} endpoint health

ETCDCTL_API=3 etcdctl \
--endpoints http://${IP_ETCD_0}:${KRV_PORT_API},http://${IP_ETCD_1}:${KRV_PORT_API},http://${IP_ETCD_2}:${KRV_PORT_API} endpoint status
