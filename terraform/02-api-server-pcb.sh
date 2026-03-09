#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.18
export IP_ETCD_1=10.0.0.23
export IP_ETCD_2=10.0.0.22
export IP_LB=10.0.0.2

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

cat <<EOF | sudo tee /etc/systemd/system/configure-nlb.service
[Unit]
Description=Configure Network Load Balancer
After=network.target

[Service]
ExecStart=/sbin/ip route add to local $IP_LB dev eth1
ExecStart=/sbin/sysctl -w net.ipv4.conf.eth1.arp_announce=2
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# apiserver-0
sudo systemctl enable configure-nlb
sudo systemctl start configure-nlb

cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.conf
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $IP_LB
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: $IP_LB:6443
etcd:
  external:
    endpoints:
      - https://$IP_ETCD_0:2379
      - https://$IP_ETCD_1:2379
      - https://$IP_ETCD_2:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
  podSubnet: 10.64.0.0/12
controllerManager:
  extraArgs:
    - name: kube-api-qps
      value: "16000"
    - name: kube-api-burst
      value: "24000"
scheduler:
  extraArgs:
    - name: kube-api-qps
      value: "16000"
    - name: kube-api-burst
      value: "24000"
EOF

kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# followers
kubeadm join 10.0.0.2:6443 --token 60raeh.hh4p3pusj117g0n1 \
        --discovery-token-ca-cert-hash sha256:8d2dcb37edf276b8859fa8581f07673057c934eb97ec952ca26651ff434ebc9c \
        --control-plane --certificate-key 1065b860924639fbb8c3c638eb6a342112c74231945219effb871b4ae063ea8e \
    --apiserver-advertise-address $HOST_IP

sudo systemctl enable configure-nlb
sudo systemctl start configure-nlb

# metrics
kubeadm join 10.0.0.2:6443 --token 60raeh.hh4p3pusj117g0n1 \
        --discovery-token-ca-cert-hash sha256:8d2dcb37edf276b8859fa8581f07673057c934eb97ec952ca26651ff434ebc9c

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#
#  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 
