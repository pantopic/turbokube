package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	ctx := context.Background()
	if len(os.Args) < 2 {
		panic("Command required [run, reset]")
	}
	var t Test
	switch os.Args[1] {
	case "run":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			t = newTestBasic(args)
			t.Start(ctx)
		}
	case "reset":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			t = newTestBasic(args)
			t.Reset(ctx)
		}
	}

	// await stop
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	signal.Notify(stop, syscall.SIGTERM)
	select {
	case <-stop:
		t.Stop()
	case <-t.Done():
	}

	println("done")
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

type Test interface {
	Start(ctx context.Context)
	Reset(ctx context.Context)
	Stop()
	Done() (done chan bool)
}
