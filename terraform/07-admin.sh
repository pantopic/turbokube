#!/bin/bash
set -e

export IP_WORKER_CTRL=10.0.0.29
export IP_APISERVER_0=10.0.0.32

scp root@$IP_WORKER_CTRL:/etcd/kubernetes/admin.conf /etcd/kubernetes/admin.a.conf
scp root@$IP_APISERVER_0:/etcd/kubernetes/admin.conf /etcd/kubernetes/admin.b.conf
cat root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.b.crt
cat root@$IP_APISERVER_0:/etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.b.key

wget https://go.dev/dl/go1.25.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.25.4.linux-amd64.tar.gz

git clone https://github.com/pantopic/turbokube.git
cd turbokube/turboctl
make run
