#!/bin/bash
set -e

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

kubeadm join 10.0.0.36:6443 --token bt9t1r.brif6v4ocq2ybo69 \
        --discovery-token-ca-cert-hash sha256:4c2c9389b12f68a5cb730a773ae22ac2e7659cfada7a03d218a86056258b2b1a \
        --node-name "$(hostname)-$(echo $HOST_IP | sed 's/\./\-/g')"

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
