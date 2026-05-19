#!/bin/bash
set -e

export IP_APISERVER_0=10.0.0.20
export IP_ETCD_0=10.0.0.4
export IP_ETCD_1=10.0.0.21
export IP_ETCD_2=10.0.0.3
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
kubeadm join 10.0.0.2:6443 --token 3rto1u.0gjut4leuc6gyts4 \
        --discovery-token-ca-cert-hash sha256:ecbb545f59f07ebf177346d7969f6961f48017facbcde12c288d1ee9dd16c10e \
        --control-plane --certificate-key 6f86230dbe3307205104a397930d1ff1d090869d70a3ddcd6784a6adb303e282 \
    --apiserver-advertise-address $HOST_IP

sudo systemctl enable configure-nlb
sudo systemctl start configure-nlb

# metrics
kubeadm join 10.0.0.2:6443 --token 6qom50.pittqa3vannjlpr7 \
        --discovery-token-ca-cert-hash sha256:cb2a324eded791db5e9c18d9a22bb480934e665e75f4bc14db906fb0c3dcc33d

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#
#  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 

export IP_APISERVER_0=10.0.0.21
cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.conf
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $IP_APISERVER_0
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: stable
controlPlaneEndpoint: $IP_APISERVER_0:6443
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
