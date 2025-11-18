#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.5
export IP_ETCD_1=10.0.0.22
export IP_ETCD_2=10.0.0.23

export KRV_PORT_API=2379
export KRV_PORT_ZONGZI=2380
export KRV_HOST_PEERS=${IP_ETCD_0}:${KRV_PORT_ZONGZI},${IP_ETCD_1}:${KRV_PORT_ZONGZI},${IP_ETCD_2}:${KRV_PORT_ZONGZI}

export KRV_TLS_CRT=/etc/kubernetes/pki/etcd/server.crt
export KRV_TLS_KEY=/etc/kubernetes/pki/etcd/server.key

# etc-0
KRV_HOST_NAME=${IP_ETCD_0} ./krv

# etc-1
KRV_HOST_NAME=${IP_ETCD_1} ./krv

# etc-2
KRV_HOST_NAME=${IP_ETCD_2} ./krv

