#!/bin/bash
set -e

export IP_KUBE_0=10.0.0.32
export IP_KUBE_1=10.0.0.29
export IP_KUBE_2=10.0.0.33
export IP_LB=10.0.0.28

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
kubeadm join $IP_LB:6443 --token 8f0xav.c0nocq1sapbr99ob \
        --discovery-token-ca-cert-hash sha256:2b9233b564a3b2b7f8e966858b70f06f56621fd24f1efcf627f1629998bca671 \
        --control-plane --certificate-key 2159b3ba50b6eb48e1406eeae1847b9cf92e793f63f6f92d1c993e51d5c551cb \
        --apiserver-advertise-address $IP_KUBE_1


kubeadm join $IP_LB:6443 --token 8f0xav.c0nocq1sapbr99ob \
        --discovery-token-ca-cert-hash sha256:2b9233b564a3b2b7f8e966858b70f06f56621fd24f1efcf627f1629998bca671 \
        --control-plane --certificate-key 2159b3ba50b6eb48e1406eeae1847b9cf92e793f63f6f92d1c993e51d5c551cb \
        --apiserver-advertise-address $IP_KUBE_2

# worker
kubeadm join 10.0.0.28:6443 --token 8f0xav.c0nocq1sapbr99ob \
        --discovery-token-ca-cert-hash sha256:2b9233b564a3b2b7f8e966858b70f06f56621fd24f1efcf627f1629998bca671
        

# Add flannel for networking
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system edit deployment/metrics-server
# --kubelet-insecure-tls

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
# > cat /etc/kubernetes/pki/apiserver.crt
# > cat /etc/kubernetes/pki/apiserver.key
# > cat /etc/kubernetes/admin.conf

