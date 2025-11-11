#!/bin/bash
set -e

kubeadm join 10.0.0.18:6443 --token 5bzirr.7bqj2afhkpcrp6ox \
        --discovery-token-ca-cert-hash sha256:cbe10ab1d51992db48420ef3bcd4467dac74c24ccde0354b1689e13395e290e9

