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
- [01-etcd.sh](01-etcd.sh) should be run on etcd nodes in *cluster B* to start etcd
- [02-apiserver.sh](02-apiserver.sh) should be run on apiserver nodes in *cluster B* to start the kubernetes cluster
- [03-scheduler.sh](03-scheduler.sh) should be run on the scheduler node in *cluster B*
- [04-controller-manager.sh](04-controller-manager.sh) should be run on the controller-manager node in *cluster B*
- [05-worker-control.sh](05-worker-control.sh) should be run on the *cluster A* control node to start the other kubernetes cluster
- [06-metrics.sh](06-metrics.sh) configures the metrics server with prometheus and grafana in *cluster B*
- [07-admin.sh](07-admin.sh) should be run on the cluster A control node to start the other kubernetes cluster
