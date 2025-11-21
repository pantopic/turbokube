#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.15
export IP_ETCD_1=10.0.0.27
export IP_ETCD_2=10.0.0.23
export IP_APISERVER_0=10.0.0.20
export IP_TURBO=10.0.0.21

mkdir -p /etc/kubernetes/pki/etcd
scp -o "StrictHostKeyChecking=accept-new" root@$IP_TURBO:/etc/kubernetes/admin.conf /etc/kubernetes/admin.a.conf
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/admin.conf /etc/kubernetes/admin.b.conf
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.b.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.b.key

wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

git clone https://github.com/pantopic/turbokube.git
cd turbokube/turboctl
go build
