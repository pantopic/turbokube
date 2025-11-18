#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

mkdir -p /etc/systemd/system/kubelet.service.d
cat > /etc/systemd/system/kubelet.service.d/20-labels-taints.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=${KUBELET_EXTRA_ARGS} --node-labels=pantopic/turbokube=scheduler --register-with-taints=pantopic/turbokube=scheduler:NoSchedule"
EOF

kubeadm join 10.0.0.35:6443 --token yxl4ye.urhwg7fw0orig88d \
        --discovery-token-ca-cert-hash sha256:c328698142c93c8f42bef740961fc1004933511d9db63442ec2e8af110e31d07

# Commands to apply taints and labels manually post-hoc if systemd conf doesn't work
#
#   kubectl taint nodes scheduler-0 pantopic/turbokube=scheduler:NoSchedule
#   kubectl label nodes scheduler-0 pantopic/turbokube=scheduler
#