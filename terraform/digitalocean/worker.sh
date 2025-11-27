#!/bin/bash
set -e

kubeadm join 10.0.0.33:6443 --token jctplr.mrk0kw4iddixbjxv \
        --discovery-token-ca-cert-hash sha256:4c6b19be6517f469026657bff5b9788832915fad9b2462d9d731b596d093085b

echo "maxPods: 1000" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
