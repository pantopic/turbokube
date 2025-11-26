#!/bin/bash
set -e

kubeadm join 10.0.0.7:6443 --token vg9rt0.g3pg98y13lpca3tm \
        --discovery-token-ca-cert-hash sha256:a72beefd703153b4169ee3a5555921e02dbe1a6314a0fc0a4bc4b2d7129fae0d

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
