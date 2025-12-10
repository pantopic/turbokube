#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.32:6443 --token cd9bqa.ea3kqvwc86ric4q8 \
        --discovery-token-ca-cert-hash sha256:c2fccf7dec558e820bb9562a9b5fb9e47a2f1cacc5b45ec5804007af02674377 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
