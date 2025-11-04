# Terraform

This directory contains terraform scripts and bash scripts for provisioning a turbokube test environment.

These environments are only designed to automate the provisioning of infrastructure to speed up the setup/teardown
process. After the infrastructure is provisioned, there is still a bit of manual legwork required to get the cluster
up and running. This is expected.

[setup.sh](digitalocean/setup.sh) runs automatically on each kube node on creation to install `kubelet`, `kubeadm` 
and `kubectl`.

The shell scripts here are expected to be altered and run manually in this order:
- 01-kubernetes.sh
