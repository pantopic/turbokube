#!/bin/bash
set -e

cat <<EOF | sudo tee /etc/systemd/system/configure-nlb.service
[Unit]
Description=Configure Network Load Balancer
After=network.target

[Service]
ExecStart=/sbin/ip route add to local api-server-lb dev eth1
ExecStart=/sbin/sysctl -w net.ipv4.conf.eth1.arp_announce=2 
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
