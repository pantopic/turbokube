#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.31:6443 --token 9fyx0k.uqwsd2i5ljl8d6ld \
        --discovery-token-ca-cert-hash sha256:f8a2b42d129799d896d1b35c0655fd3770510938cce26065654167fe5971ced4 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
