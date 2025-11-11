#!/bin/bash
set -e

kubeadm join 10.0.0.18:6443 --token hod6df.agntd2xdx4xdcxc6 \
        --discovery-token-ca-cert-hash sha256:64b1657398752d50baae84cb7d4bceae92600c3995a045f6edc25f32fc23355c
