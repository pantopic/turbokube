#!/bin/bash
set -e

export IP_WORKER_CTRL=10.0.0.29
export IP_APISERVER_0=10.0.0.32

scp root@$IP_WORKER_CTRL:/etcd/kubernetes/admin.conf /etcd/kubernetes/admin.a.conf
scp root@$IP_APISERVER_0:/etcd/kubernetes/admin.conf /etcd/kubernetes/admin.b.conf

# TODO - Download turboctl
