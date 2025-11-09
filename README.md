# TurboKube

<a href="https://www.digitalocean.com/?refcode=a16ca694958a&utm_campaign=Referral_Invite&utm_medium=Referral_Program&utm_source=badge"><img src="https://web-platforms.sfo2.cdn.digitaloceanspaces.com/WWW/Badge%203.svg" alt="DigitalOcean Referral Badge" align="right" height="65"/></a>

A fork of Virtual Kubelet's <a href="https://github.com/virtual-kubelet/virtual-kubelet/blob/main/cmd/virtual-kubelet/internal/provider/mock/mock.go">Mock Provider</a>
designed specifically to load test the Kubernetes control plane. Simulate the load of a 10,000 node cluster using a
handful of small virtual machines.

## Once upon a time on LinkedIn…

<img alt="screenshot of a conversation on linked in where people are asking why etcd is slow" src="junk/etcd.png" align="left" width="300"/>

…someone complained about Kubernetes.

This project was created to map the performance characteristics of the Kubernetes control plane.

Account limits in every available cloud provider prevent us from spinning up the 5,000 virtual machines required to
reach the published <a href="https://kubernetes.io/docs/setup/best-practices/cluster-large/">Kubernetes performance limits</a>
organically.

We will need to compress the load if we want to reach the upper echelons of Kubernetes scalability.

<a href="https://www.horriblelogos.com/turbokube/"><img alt="$10 logo from horriblelogos.com" title="$10 logo from horriblelogos.com" src="junk/turbokube.png" align="right" width="360" /></a>

Hence...

<br/><br/><br/><br/><br/><br/><br/><br/>

## Why Turbo?

A *turbocharger* in a car works by compressing air before it enters the engine so that more fuel can be burnt on every
stroke, increasing horsepower without adding more cylinders. More power, less weight.

A *turbopump* in a rocket engine works by preburning fuel and oxidizer to impel a turbine, pumping more fuel and
oxidizer at a faster rate into the main combustion chamber, increasing thrust and TWR (thrust to weight ratio).

*TurboKube* is designed to amplify the load on a Kubernetes control plane by several orders of magnitude. One worker
node in *Cluster A* can present itself as one hundred (or more) nodes in *Cluster B* (the system under load).

*TurboKube* makes Kubernetes control plane load testing faster, cheaper and easier.

## Architecture

<a href="https://app.diagrams.net/#Uhttps://raw.githubusercontent.com/pantopic/turbokube/refs/heads/main/junk/turbokube.draw.io.png"><img alt="Architectural diagram of TurboKube" title="Click to open on draw.io" src="junk/turbokube.draw.io.png"/></a>

*Control Plane A* schedules <a href="https://virtual-kubelet.io/">Virtual Kubelet</a> containers as pods in an autoscaling pool of
worker nodes. Each Virtual Kubelet operates a mock provider (TurboKube). Those Virtual Kubelets connect to
*Control Plane B*, joining the cluster pretending to be real virtual machines.

*Control Plane B* schedules Pods to these Virtual Kubelets. The pods scheduled to the Virtual Kubelets are real to
*Cluster B* but "fake" to *Cluster A* because it knows that the pods don't exececute anything in any real sense. The
Virtual Kubelet doesn't have a container runtime in which to run the containers in the pod spec. Instead, the provider
simulates the behavior of a running container including healthchecks, metrics, etc.

All of this is orchestrated with Terraform and a bunch of manually applied shell scripts. After the system is
provisioned, load tests can be run using turbokube-cli (wip) on the admin node.

## Experiment Variables

- Size of control plane instances (vertical scale, cores and ram)
- Number of control plane instances (horizontal scale)
- Types of load (few large deployments vs many small deployments)
- Topology of control plane (colocated vs offloaded: etcd, scheduler, etc)
- Configuration of control plane (api server cache size, etcd knobs, etc)

## Experiment Goals

1. Learn a lot about operating the kubernetes control plane
2. Identify soft and hard failure points
3. Publish a control plane instance size recommendation calculator
4. Test performance of alternate etcd implementations

## Results

TBD

## Adjacent Work

- [KubeMark](https://github.com/kubernetes-sigs/cluster-api-provider-kubemark)
- [KWOK](https://kwok.sigs.k8s.io/)
- [SimKube](https://github.com/acrlabs/simkube)
- [KubeBurner](https://github.com/kube-burner/kube-burner)
