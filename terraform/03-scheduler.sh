#!/bin/bash
set -e

# https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/

kubeadm join 10.0.0.2:6443 --token eapa20.wvbk9mkr3z2py3kf \
        --discovery-token-ca-cert-hash sha256:940cb820a0849eba2180f48a79a5a4d458d95f561e4099ab80d57abce4a5f430

kubectl taint nodes scheduler-0 pantopic/turbokube=scheduler:NoSchedule
kubectl label nodes scheduler-0 pantopic/turbokube=scheduler

