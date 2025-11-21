#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

# mkdir -p /etc/systemd/system/kubelet.service.d
# cat > /etc/systemd/system/kubelet.service.d/20-labels-taints.conf <<EOF
# [Service]
# Environment="KUBELET_EXTRA_ARGS=--node-labels=pantopic/turbokube=scheduler --register-with-taints=pantopic/turbokube=scheduler:NoSchedule"
# EOF

kubeadm join 10.0.0.2:6443 --token sw104m.8gk45f9uufwu1r07 \
        --discovery-token-ca-cert-hash sha256:a5a6c58f158bfc8e9a1ca8ba78973786f47b79bb359dc637238b7e795efe3dab

# Commands to apply taints and labels manually post-hoc
kubectl taint nodes scheduler-0 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-0 pantopic/turbokube=scheduler
