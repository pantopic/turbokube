#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.44
export IP_ETCD_1=10.0.0.41
export IP_ETCD_2=10.0.0.43
export IP_LB=10.0.0.42

export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

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

mkdir -p /etc/kubernetes/pki/etcd
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# control plane
kubeadm join 10.0.0.42:6443 --token hncohs.7ui93bnv64baq14h \
        --discovery-token-ca-cert-hash sha256:6e838598c45557b497a9dbdb18a93e170ff340f8dff55c5742ed315ba2b70761 \
        --control-plane --certificate-key 8494f355e8d0b3ff08eeed955d554481c697f21bcefe6dd7bfa29506b279520b \
    --apiserver-advertise-address $HOST_IP


# metrics
kubeadm join 10.0.0.42:6443 --token hncohs.7ui93bnv64baq14h \
        --discovery-token-ca-cert-hash sha256:6e838598c45557b497a9dbdb18a93e170ff340f8dff55c5742ed315ba2b70761


wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  crictl ps | grep apiserver | awk '{print $1}' | xargs crictl logs -f
#
