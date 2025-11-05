#!/bin/bash
set -e

export IP_TURBO=10.0.0.23

# leader
kubeadm init \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-advertise-address $IP_TURBO \
    --control-plane-endpoint $IP_TURBO \
    --upload-certs

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# worker
kubeadm join $IP_TURBO:6443 --token pzmlwc.w9ttie0zxq7jhplk \
    --discovery-token-ca-cert-hash sha256:82a196d09a3400dbdd0478096a71016115738c9db360a4214da99569bb4b60ca

# May need metrics server later
#
#   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Useful commands
#
#   watch kubectl get all -A
#
#   cat /var/log/cloud-init-output.log
#   tail /var/log/cloud-init-output.log -f
#   
#   kubeadm init phase upload-certs --upload-certs
#   kubeadm init phase upload-config kubeadm
#
