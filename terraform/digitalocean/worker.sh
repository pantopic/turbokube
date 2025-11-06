#!/bin/bash
set -e

kubeadm join 10.0.0.27:6443 --token gafdf2.ab2huvqwa8m62k9z \
        --discovery-token-ca-cert-hash sha256:eff3e3531e5b171d15f09a2fb483971a66220da1c869f9bb4be6e861a5b84524
