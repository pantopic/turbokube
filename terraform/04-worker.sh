#!/bin/bash
set -e

export IP_TURBO=10.0.0.33

cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.conf
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $IP_TURBO
  bindPort: 6443
---
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
      value: "21"
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
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
sed -i 's/    spec:/    spec:\n      tolerations:\n      - key: node-role.kubernetes.io\/control-plane\n        operator: Exists/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#   
#   kubectl get node | grep none | awk '{print $1}' | xargs kubectl describe node | grep turbokube | wc -l
#

cat <<EOF > wa.sh
kubectl get node | grep none | awk '{print $1}' | xargs kubectl describe node | grep -E 'Non\-terminated Pods|Name:'
EOF
chmod +x wa.sh
watch ./wa.sh