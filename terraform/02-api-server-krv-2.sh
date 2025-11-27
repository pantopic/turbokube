#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.35
export IP_ETCD_1=10.0.0.30
export IP_ETCD_2=10.0.0.31
export IP_LB=10.0.0.27

export KRV_TLS_CRT=/etc/kubernetes/pki/etcd/server.crt
export KRV_TLS_KEY=/etc/kubernetes/pki/etcd/server.key
export HOST_IP=$(ip addr show dev eth1 | grep 10.0.0 | awk '{print $2}' | sed 's/\/.*//')

export KRV_PORT_API=2379
export KRV_PORT_ZONGZI=2380
export KRV_HOST_PEERS=${IP_ETCD_0}:${KRV_PORT_ZONGZI},${IP_ETCD_1}:${KRV_PORT_ZONGZI},${IP_ETCD_2}:${KRV_PORT_ZONGZI}
export KRV_HOST_NAME=${HOST_IP}
export KRV_HOST_TAGS="pantopic/krv=nonvoting"

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
      value: "800"
    - name: kube-api-burst
      value: "1200"
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

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# followers
kubeadm join 10.0.0.35:6443 --token xmb2wc.117mxigm1e4dw3ki \
    --discovery-token-ca-cert-hash sha256:ad2bec2b4c294b44022ac6454454bb55593e9be325794bdf08f40b60688b30b3 \
    --control-plane --certificate-key 74de487df0912bb7d2254e07eec2d879023d144040f98dc716b1abf452afa4c9

# metrics
kubeadm join 10.0.0.43:6443 --token weyod3.2tsi0xt3giax7v1q \
        --discovery-token-ca-cert-hash sha256:3d66c594423ffa17f2ff656acdd54568f626dbb30415ee8c42128e3feb72f41e

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#
