#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.45:6443 --token x96q2v.rx4g09m0tmhg08kh \
        --discovery-token-ca-cert-hash sha256:d9ed67e08edd9331fb4723a49a4b87674e506156b21143b5d539c69761d82ea2 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
