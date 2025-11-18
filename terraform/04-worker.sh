#!/bin/bash
set -e

export IP_TURBO=10.0.0.4

cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.conf
apiServer: 
  advertiseAddress: $IP_TURBO
apiVersion: kubeadm.k8s.io/v1beta4
caCertificateValidityPeriod: 87600h0m0s
certificateValidityPeriod: 8760h0m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: $IP_TURBO:6443
controllerManager:
  extraArgs:
    - name: node-cidr-mask-size
      value: "20"
dns: {}
encryptionAlgorithm: RSA-2048
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: v1.34.1
networking:
  dnsDomain: cluster.local
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
proxy: {}
scheduler: {}
EOF

# leader
kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Fix metrics server configuration to not be a giant PITA
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
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
#   doctl registry kubernetes-manifest
#
