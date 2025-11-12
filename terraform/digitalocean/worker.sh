#!/bin/bash
set -e

kubeadm join 10.0.0.15:6443 --token xg4e2z.4032zqvlvy9t7wzq \
        --discovery-token-ca-cert-hash sha256:9080295d03767b2666f10be3953ec2b8534bd139c1cde061ec70484bdfc3b9f7
