# TurboKube

A fork of the [Virtual Kubelet](https://virtual-kubelet.io/) [Mock Provider](https://github.com/virtual-kubelet/virtual-kubelet/blob/main/cmd/virtual-kubelet/internal/provider/mock/mock.go) customized for load testing the Kubernetes Control Plane.

## A long time ago in a galaxy far, far away…

<img alt="screenshot of a conversation on linked in where people are asking why etcd is slow" src="junk/etcd.png" align="left" width="300"/>

Someone complained about Kubernetes.

This project was created to explore the performance characteristics of the Kubernetes control plane.

Account limits in every available cloud provider would prevent us from spinning up the 5,000 nodes required to reach
the published [Kubernetes performance limits](https://kubernetes.io/docs/setup/best-practices/cluster-large/).

We will need to compress the load if we want to reach the upper echelons of Kubernetes scalability.

[<img alt="$10 logo from horriblelogos.com" title="$10 logo from horriblelogos.com" src="junk/turbokube.png" align="right" width="360" />](https://www.horriblelogos.com/turbokube/)

Hence...

<br/><br/><br/><br/><br/><br/><br/><br/>

## Why Turbo?

A *turbo charger* works by compressing air before it enters the engine cylinder of a car so that more fuel can be
burnt on every stroke, increasing horsepower.

*TurboKube* is like a turbo charger because it amplifies load on a Kubernetes control plane by enabling one node in
*Cluster A* to present itself as a hundred nodes to *Cluster B* (the cluster under load).

## Architecture

[<img alt="Architectural diagram of TurboKube" title="Click to open on draw.io" src="junk/turbokube.draw.io.png"/>](https://app.diagrams.net/#Uhttps%3A%2F%2Fgithub.com%2Fpantopic%2Fturbokube%2Fblob%2Fmain%2Fjunk%2Fturbokube.draw.io.png)

*Control Plane A* schedules [Virtual Kubelet](https://virtual-kubelet.io/) containers as pods in an autoscaling pool of worker nodes.

Those Virtual Kubelets connect to *Control Plane B*, joining the cluster as available nodes.

*Control Plane B* schedules Pods to the Virtual Kubelets.

Each Virtual Kubelet operates a mock provider (TurboKube).

The pods scheduled to the Virtual Kubelets are "fake" because they don't exececute in any real sense since the Virtual
Kubelet doesn't have a container runtime. The Virtual Kubelet provider simulates the behavior of a running container
including healthchecks, metrics, etc.

This allows us to simulate a 10,000 node cluster using only a handful nodes.

*Control Plane B* is the system under test.

All of this is orchestrated with Terraform and a bunch of manually applied shell scripts.

After the system is provisioned, performance tests are run using [kube-burner](https://github.com/kube-burner/kube-burner) (wip).

## Experiment Variables

- Size of control plane instances (cores and ram)
- Control plane topology (colocated vs dedicated etcd, offloaded scheduler, etc)
- Load types (few large deployments vs many small deployments)

## Experiment Goals

1. Learn a lot about operating kubernetes and etcd
2. Identify soft and hard failure points
3. Publish a control plane instance size recommendation calculator
4. Test performance of alternate etcd implementations
