#!/bin/bash
set -e

kubeadm join 10.0.0.21:6443 --token ca2ada.0mpbc7f6eds7e6bm \
        --discovery-token-ca-cert-hash sha256:1439dd3f4b4b9ebacbfe3d8dc46665fae76cad914d35efe360d3244d0bb24555

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
