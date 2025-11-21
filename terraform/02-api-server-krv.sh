#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.10
export IP_ETCD_1=10.0.0.17
export IP_ETCD_2=10.0.0.6
export IP_LB=10.0.0.35

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
  podSubnet: 10.244.0.0/16
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

# leader
mkdir -p /etc/kubernetes/pki/etcd
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

# followers
kubeadm join 10.0.0.35:6443 --token xmb2wc.117mxigm1e4dw3ki \
    --discovery-token-ca-cert-hash sha256:ad2bec2b4c294b44022ac6454454bb55593e9be325794bdf08f40b60688b30b3 \
    --control-plane --certificate-key 74de487df0912bb7d2254e07eec2d879023d144040f98dc716b1abf452afa4c9

# metrics
kubeadm join 10.0.0.35:6443 --token 8z1qdj.wd4q0dou1aqa5dhs \
        --discovery-token-ca-cert-hash sha256:73254dc1eeb92d9b0ea411810e68c9f79eba2a4b1262d80223fe22b4de66e556
        

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#

export KRV_ENDPOINTS=https://${IP_ETCD_0}:2379,https://${IP_ETCD_1}:2379,https://${IP_ETCD_2}:2379

etcdctl \
--cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints ${KRV_ENDPOINTS} endpoint health

etcdctl --endpoints ${KRV_ENDPOINTS} endpoint health


etcdctl \
--cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints ${KRV_ENDPOINTS} put "test" "test"

etcdctl \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints ${KRV_ENDPOINTS} get --keys-only --prefix=true ""

etcdctl --endpoints ${KRV_ENDPOINTS} endpoint health
etcdctl --endpoints ${KRV_ENDPOINTS} endpoint status
ETCDCTL_API=3 etcdctl --endpoints ${KRV_ENDPOINTS} get --keys-only --prefix=true ""

etcdctl \
--cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
--key /etc/kubernetes/pki/apiserver-etcd-client.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints ${KRV_ENDPOINTS} get --keys-only --prefix=true ""