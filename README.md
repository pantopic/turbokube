# A long time ago in a galaxy far, far away…

<img alt="screenshot of a conversation on linked in where people are asking why etcd is slow" src="junk/etcd.png" align="left" width="300"/>

Someone complained about Kubernetes.

This project was created to explore the performance characteristics of the Kubernetes control plane.

Account limits in every available cloud provider would prevent us from spinning up the 5,000 nodes required to reach
the published [Kubernetes performance limits](https://kubernetes.io/docs/setup/best-practices/cluster-large/).

We will need to compress the load if we want to reach the upper echelons of Kubernetes scalability.

[<img alt="$10 logo from horriblelogos.com" title="$10 logo from horriblelogos.com" src="junk/turbokube.png" align="right" width="360" />](https://www.horriblelogos.com/turbokube/)

Hence...
