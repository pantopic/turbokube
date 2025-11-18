#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

cat > /etc/systemd/system/kubelet.service.d/20-labels-taints.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--node-labels=pantopic/turbokube=scheduler --register-with-taints=pantopic/turbokube=scheduler:NoSchedule"
EOF

kubeadm join 10.0.0.2:6443 --token tpbgnw.mph1m8tbtshg2s87 \
        --discovery-token-ca-cert-hash sha256:8a88425a52558190f65b54e52062aa352b9a6b48443ae1e5f9fef4e5b0512f79
