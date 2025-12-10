#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

# mkdir -p /etc/systemd/system/kubelet.service.d
# cat > /etc/systemd/system/kubelet.service.d/20-labels-taints.conf <<EOF
# [Service]
# Environment="KUBELET_EXTRA_ARGS=--node-labels=pantopic/turbokube=scheduler --register-with-taints=pantopic/turbokube=scheduler:NoSchedule"
# EOF

kubeadm join 10.0.0.41:6443 --token ijq3gx.1w11txtbiv7cw9x8 \
        --discovery-token-ca-cert-hash sha256:6f6700c1bc36dce47f774824bfe71cd2cb3789211b8d48386debec262f42109b

# Commands to apply taints and labels manually post-hoc
kubectl taint nodes scheduler-0 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-0 pantopic/turbokube=scheduler
kubectl taint nodes scheduler-1 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-1 pantopic/turbokube=scheduler
kubectl taint nodes scheduler-2 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-2 pantopic/turbokube=scheduler
kubectl taint nodes scheduler-3 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-3 pantopic/turbokube=scheduler

# ---


