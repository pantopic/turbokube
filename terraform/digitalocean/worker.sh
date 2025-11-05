#!/bin/bash
set -e

sudo apt-get install -y zip

# Download binary
wget https://raw.githubusercontent.com/pantopic/turbokube/main/bin/virtual-kubelet.zip
unzip virtual-kubelet.zip
chmod 755 virtual-kubelet
sudo ln -s virtual-kubelet /bin/virtual-kubelet

sudo mkdir -p /etc/turbokube
sudo chmod 644 /etc/turbokube

# Environment variables for virtual kubelet
cat <<EOF | sudo tee /etc/turbokube/env
NODE_NAME=$hostname
KUBECONFIG=/etc/turbokube/config.yaml
EOF

# Create systemd service
cat <<EOF | sudo tee /etc/systemd/system/turbokube.service
[Unit]
Description=Tha whistles go WOOO!
After=network.target

[Service]
Type=simple
ExecStart=/bin/virtual-kubelet
EnvironmentFile=-/etc/turbokube/env
RemainAfterExit=no
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Configure kubelet
cat <<EOF | sudo tee /etc/turbokube/config.yaml
###################
##  [ REPLACE ]  ##
###################
EOF

# Start systemd service
sudo systemctl enable turbokube
sudo systemctl start turbokube
