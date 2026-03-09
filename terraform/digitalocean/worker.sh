#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.16:6443 --token 7ckmgc.skhi9bg3kpvwalyi \
        --discovery-token-ca-cert-hash sha256:7cb6d2010a73c489fa0da6cf7c9b511bede4f19576f1c5bbc563e32d2d87b265 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
