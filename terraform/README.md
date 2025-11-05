# Terraform

This directory contains terraform scripts and bash scripts for provisioning a turbokube test environment.

These environments are only designed to automate the provisioning of infrastructure to speed up the setup/teardown
process. After the infrastructure is provisioned, there is still a bit of manual legwork required to get the cluster
up and running. This is expected.

Digitalocean is the only cloud provider presently supported. That's only because it's the cloud provider where the
author presently has the highest service limits.

[setup.sh](digitalocean/setup.sh) runs automatically on each kube node on creation to install `kubelet`, `kubeadm` 
and `kubectl`.

The shell scripts here are expected to be altered based on output from terraform and kubeadm. They should be run
manually in this order:
- [01-kube.sh](01-kube.sh) should be run on the control nodes to start the kubernetes cluster
