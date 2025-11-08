#!/bin/bash
set -e

kubeadm join 10.0.0.30:6443 --token h5eld9.xk09154lz130fka6 \
        --discovery-token-ca-cert-hash sha256:d1a04c50f10b836b041ae10c215f9f08601f0c317695af4d1ac389819e09304e
