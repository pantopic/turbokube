#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.18:6443 --token vkiy85.tsj6yh42jllrenzc \
        --discovery-token-ca-cert-hash sha256:5b31262d0e52b1b93c6a369a0ffee713744e93c15a47d7c328b2dcf0a48042af \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
