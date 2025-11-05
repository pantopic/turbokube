#!/bin/bash
set -e

export IP_KUBE_0=10.0.0.26
export IP_KUBE_1=10.0.0.25
export IP_KUBE_2=10.0.0.24
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

# peers
kubeadm join $IP_LB:6443 --token 5g2v8a.08l9jltmfrgpvcra \
        --discovery-token-ca-cert-hash sha256:964f62206d28d6e323e416ae47679ab8559a47e85b3bdd641713b10807535d65 \
        --control-plane --certificate-key f202e213c68bba77bf23d6a7f217d23ead021506cfb260647cc9e8360bffc001 \
    --apiserver-advertise-address $IP_KUBE_1


kubeadm join $IP_LB:6443 --token 5g2v8a.08l9jltmfrgpvcra \
        --discovery-token-ca-cert-hash sha256:964f62206d28d6e323e416ae47679ab8559a47e85b3bdd641713b10807535d65 \
        --control-plane --certificate-key f202e213c68bba77bf23d6a7f217d23ead021506cfb260647cc9e8360bffc001 \
    --apiserver-advertise-address $IP_KUBE_2

# worker
kubeadm join 10.0.0.5:6443 --token pzmlwc.w9ttie0zxq7jhplk \
    --discovery-token-ca-cert-hash sha256:82a196d09a3400dbdd0478096a71016115738c9db360a4214da99569bb4b60ca

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# May need metrics server later
#
#   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Useful commands
#
#   watch kubectl get all -A
#
#   cat /var/log/cloud-init-output.log
#   tail /var/log/cloud-init-output.log -f
#   
#   kubeadm init phase upload-certs --upload-certs
#   kubeadm init phase upload-config kubeadm
#
# > cat /etc/kubernetes/pki/ca.crt
# > cat /etc/kubernetes/pki/apiserver.key
# > cat /etc/kubernetes/pki/apiserver.crt



