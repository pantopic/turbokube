#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.18
export IP_ETCD_1=10.0.0.28
export IP_ETCD_2=10.0.0.22
export IP_LB=10.0.0.2

export KRV_TLS_CRT=/etc/kubernetes/pki/etcd/server.crt
export KRV_TLS_KEY=/etc/kubernetes/pki/etcd/server.key
export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

export KRV_PORT_API=2379
export KRV_PORT_ZONGZI=2380
export KRV_HOST_PEERS=${IP_ETCD_0}:${KRV_PORT_ZONGZI},${IP_ETCD_1}:${KRV_PORT_ZONGZI},${IP_ETCD_2}:${KRV_PORT_ZONGZI}
export KRV_HOST_NAME=${HOST_IP}
export KRV_HOST_TAGS="pantopic/krv=nonvoting"

# apiserver-0
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
      - https://$HOST_IP:2379
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
  podSubnet: 10.244.0.0/16
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

sudo systemctl enable configure-nlb
sudo systemctl start configure-nlb

# all
nohup /usr/bin/krv &

# leader
kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# followers
kubeadm join 10.0.0.2:6443 --token 242ctb.yk8m0biafagkqsvm \
        --discovery-token-ca-cert-hash sha256:faac60d1c0e23e545ed5b23f9bfa84ed4cf2f82ea0312ea9a6c7d6c73ae5e985 \
        --control-plane --certificate-key b651815dab928c782c3154353f7ed15538b15b59e1980626cadbcd8de1b45e0b \
    --apiserver-advertise-address $HOST_IP

# metrics
kubeadm join 10.0.0.2:6443 --token 242ctb.yk8m0biafagkqsvm \
        --discovery-token-ca-cert-hash sha256:faac60d1c0e23e545ed5b23f9bfa84ed4cf2f82ea0312ea9a6c7d6c73ae5e985

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#
#  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 