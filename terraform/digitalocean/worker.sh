#!/bin/bash
set -e

kubeadm join 10.0.0.26:6443 --token adq826.yst4hkce3ihg1700 \
        --discovery-token-ca-cert-hash sha256:08a769a0f7d065c8f8439a5973662d14a1443d149c6772168f9be429838714fc

echo "maxPods: 2026" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
