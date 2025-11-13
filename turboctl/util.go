package main

import (
	"encoding/json"
	"os"
	"strings"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func mustRead(path string) string {
	b, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return string(b)
}

func getClient(conf string) (clientset *kubernetes.Clientset) {
	config, err := clientcmd.BuildConfigFromFlags("", conf)
	if err != nil {
		panic(err)
	}
	clientset, err = kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	return
}

func dump(subject any) string {
	b, err := json.MarshalIndent(subject, "", "\t")
	if err != nil {
		panic(err)
	}
	return string(b)
}
func isNotFound(err error) bool {
	return strings.Contains(err.Error(), "not found")
}
