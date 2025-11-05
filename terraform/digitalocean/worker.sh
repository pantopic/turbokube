#!/bin/bash
set -e

kubeadm join 10.0.0.23:6443 --token 4sz2ss.pm7y2x9dis08gjm6 \
        --discovery-token-ca-cert-hash sha256:1d6df86b31ebb214478d2225b0e295374306f078dbb53bcc61f6180da1750f78

