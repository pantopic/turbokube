#!/bin/bash
set -e

export IP_ETCD_0=10.0.0.17
export IP_ETCD_1=10.0.0.19
export IP_ETCD_2=10.0.0.16
export IP_LB=10.0.0.35

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
scp root@$IP_ETCD_0:/etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/ca.crt
scp root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
scp root@$IP_ETCD_0:/etc/kubernetes/pki/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key

kubeadm init \
  --config /etc/kubernetes/kubeadm-config.conf \
  --upload-certs

# control plane
  kubeadm join 10.0.0.35:6443 --token qf7dvu.kwdk07eviq0i2btw \
        --discovery-token-ca-cert-hash sha256:54141669ddda56478b768d1db6a6d9f12bfca4d1fd3e64a41a90c116d6468eeb \
        --control-plane --certificate-key abaeae9d899fb5592d1606f304d3d09d1dfa5710087f8ea6bc0d5ce1e8420ad1

# worker
kubeadm join 10.0.0.35:6443 --token anii5n.8kl9972920l372t6 \
        --discovery-token-ca-cert-hash sha256:eab7e57d120480e5521c5e9c52d9a21c9a3f03a1f3f4285ebd40ab2207dabd01


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
cat /etc/kubernetes/pki/apiserver.crt
cat /etc/kubernetes/pki/apiserver.key
cat /etc/kubernetes/admin.conf

