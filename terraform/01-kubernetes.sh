#!/bin/bash
set -e

export IP_KUBE_0=10.0.0.20
export IP_KUBE_1=10.0.0.21
export IP_KUBE_2=10.0.0.22
export IP_LB=10.0.0.19

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
kubeadm init \
    --pod-network-cidr 10.244.0.0/16 \
    --apiserver-advertise-address $IP_KUBE_0 \
    --control-plane-endpoint $IP_LB \
    --upload-certs

# peer  
kubeadm join $IP_LB:6443 --token r2epvn.ghohch5h06z8xtxt \
    --discovery-token-ca-cert-hash sha256:4f8e197d74c77056135df85190203f4a43808d2be7813ba07592e0cec9368bb9 \
    --control-plane --certificate-key bfb8e941611eeefe0b0caba557a5c1bfe5ded5fefdc45a820c734e502ba38483 \
    --apiserver-advertise-address $IP_KUBE_1


kubeadm join $IP_LB:6443 --token r2epvn.ghohch5h06z8xtxt \
    --discovery-token-ca-cert-hash sha256:4f8e197d74c77056135df85190203f4a43808d2be7813ba07592e0cec9368bb9 \
    --control-plane --certificate-key bfb8e941611eeefe0b0caba557a5c1bfe5ded5fefdc45a820c734e502ba38483 \
    --apiserver-advertise-address $IP_KUBE_2
# worker
kubeadm join 10.0.0.5:6443 --token pzmlwc.w9ttie0zxq7jhplk \
    --discovery-token-ca-cert-hash sha256:82a196d09a3400dbdd0478096a71016115738c9db360a4214da99569bb4b60ca

# ---

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
