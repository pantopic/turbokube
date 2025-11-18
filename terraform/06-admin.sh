#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.29
export IP_ETCD_1=10.0.0.34
export IP_ETCD_2=10.0.0.32
export IP_APISERVER_0=10.0.0.28
export IP_TURBO=10.0.0.31

mkdir -p /etc/kubernetes/pki/etcd
scp -o "StrictHostKeyChecking=accept-new" root@$IP_TURBO:/etc/kubernetes/admin.conf /etc/kubernetes/admin.a.conf
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/admin.conf /etc/kubernetes/admin.b.conf
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.b.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.b.key
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

git clone https://github.com/pantopic/turbokube.git
cd turbokube/turboctl
go build
