#!/bin/bash
set -e

kubeadm join 10.0.0.15:6443 --token 75oh9u.3owcejicb8dg2tez \
        --discovery-token-ca-cert-hash sha256:204ab4fce8b58afc5281a5d6eeb7288d9b0a2056013a45bc39827451d842b7c2

echo "maxPods: 2026" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
