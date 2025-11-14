#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.9
export IP_ETCD_1=10.0.0.15
export IP_ETCD_2=10.0.0.7
export IP_LB=10.0.0.20

cat <<EOF | sudo tee /etc/kubernetes/kubeadm-config.conf
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

mkdir -p /etc/kubernetes/pki/etcd
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp -o "StrictHostKeyChecking=accept-new" root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

# control plane
  kubeadm join 10.0.0.35:6443 --token xmb2wc.117mxigm1e4dw3ki \
        --discovery-token-ca-cert-hash sha256:ad2bec2b4c294b44022ac6454454bb55593e9be325794bdf08f40b60688b30b3 \
        --control-plane --certificate-key 74de487df0912bb7d2254e07eec2d879023d144040f98dc716b1abf452afa4c9

# metrics
kubeadm join 10.0.0.35:6443 --token xmb2wc.117mxigm1e4dw3ki \
        --discovery-token-ca-cert-hash sha256:ad2bec2b4c294b44022ac6454454bb55593e9be325794bdf08f40b60688b30b3

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i 's/--metric-resolution=15s/--metric-resolution=15s\n        - --kubelet-insecure-tls/' components.yaml
kubectl apply -f components.yaml

# Useful commands
#
#  cat /run/systemd/resolve/resolv.conf
#
#   watch kubectl get all -A
#
#   cat /var/log/cloud-init-output.log
#   tail /var/log/cloud-init-output.log -f
#   
#   kubeadm init phase upload-certs --upload-certs
#   kubeadm init phase upload-config kubeadm
#
# cat /etc/kubernetes/pki/apiserver.crt
# cat /etc/kubernetes/pki/apiserver.key
# cat /etc/kubernetes/admin.conf
