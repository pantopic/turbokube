#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

# mkdir -p /etc/systemd/system/kubelet.service.d
# cat > /etc/systemd/system/kubelet.service.d/20-labels-taints.conf <<EOF
# [Service]
# Environment="KUBELET_EXTRA_ARGS=--node-labels=pantopic/turbokube=scheduler --register-with-taints=pantopic/turbokube=scheduler:NoSchedule"
# EOF

kubeadm join 10.0.0.2:6443 --token l1fr3u.61p7mmlkuggarrv1 \
        --discovery-token-ca-cert-hash sha256:ade41cce34090dec66aafbede7b02a4429f16e341ed86ad368252621b2eab334

# Commands to apply taints and labels manually post-hoc
kubectl taint nodes scheduler-0 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-0 pantopic/turbokube=scheduler

# ---


