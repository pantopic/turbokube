package main

import (
	"context"
	"flag"
	"os"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	ctx := context.Background()
	fs := flag.FlagSet{}
	var (
		concurrency = fs.Int("c", 1, "Concurrency")
		kube_a      = fs.String("conf", "/etc/kubernetes/admin.a.conf", "Kubernetes configuration file path")
		kube_b      = fs.String("conf", "/etc/kubernetes/admin.b.conf", "Kubernetes configuration file path")
	)
	err := fs.Parse(os.Args[1:])
	if err != nil {
		return
	}
	config, err := clientcmd.BuildConfigFromFlags("", *kube_a)
	if err != nil {
		panic(err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	// Parse inputs
	// Load api server client
	//   run test
	//     Begin test
	//     Create nodes
	//     Create namespace
	//     Create
	//   run proxy
	//     Listen for gRPC connections
	//     Provision turbokubes

	println("Tha whistles go WOOO")
}
