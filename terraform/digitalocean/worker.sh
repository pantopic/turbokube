#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.53:6443 --token wb4arn.xz8hxw5kskj5qii5 \
        --discovery-token-ca-cert-hash sha256:a9bd422a6ba90429dd7ffce40c86fbbeb846d9acf871cbc53a37f98b03734492 \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
