#!/bin/bash
set -e

kubeadm join 10.0.0.17:6443 --token wzem7g.ieiv5ckgw1ou0sgm \
        --discovery-token-ca-cert-hash sha256:45ae6e848a8c760c37a1e85fc1598d738f5b236bd176ac1a25b0a55caea3f76f

echo "maxPods: 2026" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
