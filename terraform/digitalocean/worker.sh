#!/bin/bash
set -e

kubeadm join 10.0.0.15:6443 --token n4d1qi.ps5u1v9dseb9i4tg \
        --discovery-token-ca-cert-hash sha256:d2b638d91bc66b54a98ad17431d360c0bb8c22b8c23a321443e549ae3680452a
