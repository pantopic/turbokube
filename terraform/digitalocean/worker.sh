#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.20:6443 --token yurd1w.jis5p09gp3lm5vuv \
        --discovery-token-ca-cert-hash sha256:7d5e35ba03c9b0922dc4f205ce804a7d404bd12e0fee1f02816d980eba722e0d \
        --node-name "$(hostname)-$($HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
