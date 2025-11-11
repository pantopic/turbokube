#!/bin/bash
set -e

kubeadm join 10.0.0.29:6443 --token qa4d2m.xse81d53bjaj7dvl \
        --discovery-token-ca-cert-hash sha256:a13dfb11ff2847a7a151e848ad3c0a17c1b908e6926ff8012e8e5f8f2b1d678e

cat <<EOF | sudo tee /etc/systemd/system/configure-nlb.service
[Unit]
Description=Configure Network Load Balancer
After=network.target

[Service]
ExecStart=/sbin/ip route add to local 10.0.0.29 dev eth1
ExecStart=/sbin/sysctl -w net.ipv4.conf.eth1.arp_announce=2
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable configure-nlb
sudo systemctl start configure-nlb
