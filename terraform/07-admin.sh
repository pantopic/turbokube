#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.16
export IP_ETCD_1=10.0.0.19
export IP_ETCD_2=10.0.0.17
export IP_WORKER_CTRL=10.0.0.15
export IP_APISERVER_0=10.0.0.13

scp root@$IP_WORKER_CTRL:/etc/kubernetes/admin.conf /etc/kubernetes/admin.a.conf
scp root@$IP_APISERVER_0:/etc/kubernetes/admin.conf /etc/kubernetes/admin.b.conf
scp root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.b.crt
scp root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.b.key

mkdir -p /etc/kubernetes/pki/etcd
scp root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

git clone https://github.com/pantopic/turbokube.git
cd turbokube/turboctl
make run

ETCDCTL_API=3 etcdctl \
--cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://${IP_ETCD_0}:2379,https://${IP_ETCD_1}:2379,https://${IP_ETCD_2}:2379 endpoint health