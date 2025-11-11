#!/bin/bash
set -e

export IP_TURBO=10.0.0.17

# leader
kubeadm init \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-advertise-address $IP_TURBO \
    --control-plane-endpoint $IP_TURBO \
    --upload-certs

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Fix metrics server configuration to not be a giant PITA
sed -i 's/--metric-resolution=15s/"--metric-resolution=15s --kubelet-preferred-address-types=InternalIP --kubelet-insecure-tls"/' components.yaml
# Allow metrics server to run on worker control node
sed -i 's/    spec:/    spec:\n      tolerations:\n      - key: node-role.kubernetes.io\/control-plane\n        operator: Exists/' components.yaml
kubectl apply -f components.yaml

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
#   k get secret -n kube-prometheus-stack kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
#   kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8080:80
#   kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8081:80
#
#   
  tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
