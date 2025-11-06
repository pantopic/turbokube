#!/bin/bash
set -e

export IP_KUBE_0=10.0.0.26
export IP_KUBE_1=10.0.0.22
export IP_KUBE_2=10.0.0.25
export IP_LB=10.0.0.20

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
kubeadm join $IP_LB:6443 --token nskwg6.r6949abxzcn6dyls \
        --discovery-token-ca-cert-hash sha256:e7f90cf5d71d0a74e5cb8a021dd6703cce7691a511e73e54d8d169688dbfe248 \
        --control-plane --certificate-key b8a98da2ecc6ccdfd754665e04c93222e9080e181fceafee48d206b59a7329fb \
        --apiserver-advertise-address $IP_KUBE_1


kubeadm join $IP_LB:6443 --token nskwg6.r6949abxzcn6dyls \
        --discovery-token-ca-cert-hash sha256:e7f90cf5d71d0a74e5cb8a021dd6703cce7691a511e73e54d8d169688dbfe248 \
        --control-plane --certificate-key b8a98da2ecc6ccdfd754665e04c93222e9080e181fceafee48d206b59a7329fb \
        --apiserver-advertise-address $IP_KUBE_2

# worker
kubeadm join 10.0.0.20:6443 --token nskwg6.r6949abxzcn6dyls \
        --discovery-token-ca-cert-hash sha256:e7f90cf5d71d0a74e5cb8a021dd6703cce7691a511e73e54d8d169688dbfe248

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

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
# > cat /etc/kubernetes/pki/apiserver.key
# > cat /etc/kubernetes/pki/apiserver.crt
# > cat /etc/kubernetes/admin.conf

