#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.50:6443 --token 7sbvlt.7xijcyurrhz6qtzs \
        --discovery-token-ca-cert-hash sha256:dd3f2dfa7c9554c1ffe47f0b9e6a3d4105b9c0348f3d5192b280a0c5da887e74 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
