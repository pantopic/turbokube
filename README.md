# TurboKube

A Kubernetes load testing framework

[<img alt="$10 logo from horriblelogos.com" title="$10 logo from horriblelogos.com" src="junk/turbokube.png" />](https://www.horriblelogos.com/turbokube/)

## A long time ago in a galaxy far, far away…

<img alt="screenshot of a conversation on linked in where people are asking why etcd is slow" src="junk/etcd.png" align="left" width="300"/>

Someone complained about Kubernetes on LinkedIn.

This project was created to explore the performance characteristics of the Kubernetes control plane.

Account limits in every available cloud provider would prevent us from spinning up 5,000 nodes to reach
[the published Kubernetes performance conditions](https://kubernetes.io/docs/setup/best-practices/cluster-large/)
necessary to stress test its outer limits.

We will need to compress the load if we want to reach the upper echelons of Kubernetes scalability.

Hence TurboKube.
