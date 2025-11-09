package main

import (
	"context"
	"flag"
	"sync"

	"k8s.io/client-go/kubernetes"
)

type testBasic struct {
	async    bool
	c        int
	client_a *kubernetes.Clientset
	client_b *kubernetes.Clientset
	n        int
	stop     chan bool
	tpl      string
	wg       sync.WaitGroup
}

func newTestBasic(args []string) *testBasic {
	fs := flag.FlagSet{}
	var (
		async  = fs.Bool("async", false, "Do not wait for provisioning")
		c      = fs.Int("c", 1, "Concurrency (default 1)")
		conf_a = fs.String("confa", "/etc/kubernetes/admin.a.conf", "Kubeconfig for cluster A (default /etc/kubernetes/admin.a.conf)")
		conf_b = fs.String("confb", "/etc/kubernetes/admin.b.conf", "Kubeconfig for cluster B (default /etc/kubernetes/admin.b.conf)")
		n      = fs.Int("n", 0, "Number of namespaces to create (default 0 = infinite)")
		tpl    = fs.String("tpl", "base", "Template (default \"base\")")
	)
	err := fs.Parse(args)
	if err != nil {
		panic(err)
	}
	return &testBasic{
		async:    *async,
		c:        *c,
		client_a: getClient(*conf_a),
		client_b: getClient(*conf_b),
		n:        *n,
		tpl:      *tpl,
	}
}

func (t *testBasic) Start(ctx context.Context) {
	t.stop = make(chan bool)
	t.wg.Add(1)
	go func() {
		defer t.wg.Done()
		t.run(ctx)
	}()
}

func (t *testBasic) run(ctx context.Context) {
	// Detect status
	// Create namespaces
	//   Create nodes
	//   Create namespace
	//   Create deployment(s)
	//   Create service(s)
	//   Create configmap(s)
	//   Create secret(s)
}

func (t *testBasic) Reset(ctx context.Context) {
	// Delete namespaces
	// Delete nodes
}

func (t *testBasic) Stop() {
	close(t.stop)
	t.wg.Wait()
}

func (t *testBasic) Done() (done chan bool) {
	go func() {
		t.wg.Wait()
		close(done)
	}()
	return
}
