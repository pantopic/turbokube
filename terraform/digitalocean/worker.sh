#!/bin/bash
set -e

kubeadm join 10.0.0.33:6443 --token 8xp9mo.7ywrf8vgh1n0niu7 \
        --discovery-token-ca-cert-hash sha256:fcc2ad162f0bd80a6648653b061d1bfd07ef123294acd5fd437eed0d99929d34

echo "maxPods: 2026" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
