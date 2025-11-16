#!/bin/bash
set -e

kubeadm join 10.0.0.4:6443 --token pg5egv.bpg2ohlw595xrle0 \
        --discovery-token-ca-cert-hash sha256:59e2bf3d95af71d4de0cedceb4dfcf453ad2c6073c56ad3daab2f1aeb898a69a

echo "maxPods: 2026" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
