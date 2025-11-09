#!/bin/bash
set -e

sudo apt-get update
sudo swapoff -a

# lsmod | grep overlay / br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo NEEDRESTART_MODE=a apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl git make
sudo apt-mark hold kubelet kubeadm kubectl

sudo apt-get install -y containerd

sudo mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo service containerd restart

sudo systemctl enable --now kubelet

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

cat <<EOF | sudo tee -a ~/.bashrc
export KUBE_EDITOR='nano'
export KUBECONFIG=/etc/kubernetes/admin.conf
alias k='kubectl'
alias l='ls -la'
PS1='${debian_chroot:+($debian_chroot)}\[\033[00;32m\]\h \[\033[00;33m\]\w\[\033[00m\]\n> '
EOF
source ~/.bashrc
