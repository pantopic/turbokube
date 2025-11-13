package main

import (
	"bytes"
	"context"

	"embed"
	"flag"
	"fmt"
	"log"
	"sync"
	"text/template"
	"time"

	"github.com/Masterminds/sprig/v3"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/apimachinery/pkg/watch"
	"k8s.io/client-go/kubernetes"
)

//go:embed tpl
var templates embed.FS

type testBasic struct {
	async       bool
	concurrency int
	deployments int
	client_a    *kubernetes.Clientset
	client_b    *kubernetes.Clientset
	input       Input
	n           int
	pause       int
	tpl         *template.Template
	wg          *sync.WaitGroup
}

func newTestBasic(args []string) *testBasic {
	fs := flag.FlagSet{}
	var (
		async       = fs.Bool("async", false, "Do not wait for provisioning")
		concurrency = fs.Int("c", 1, "Concurrency (default 1)")
		conf_a      = fs.String("confa", "/etc/kubernetes/admin.a.conf", "Kubeconfig for cluster A (default /etc/kubernetes/admin.a.conf)")
		conf_b      = fs.String("confb", "/etc/kubernetes/admin.b.conf", "Kubeconfig for cluster B (default /etc/kubernetes/admin.b.conf)")
		crt         = fs.String("crt", "/etc/kubernetes/pki/apiserver.b.crt", "API Server Crt for cluster B (default /etc/kubernetes/pki/apiserver.b.crt)")
		deployments = fs.Int("d", 4, "Number of deployments per namespace (default 4)")
		key         = fs.String("key", "/etc/kubernetes/pki/apiserver.b.key", "API Server Key for cluster B (default /etc/kubernetes/pki/apiserver.b.key)")
		pause       = fs.Int("p", 1, "Pause in seconds between namespace creations (default 1)")
		n           = fs.Int("n", 0, "Number of namespaces to create (default 0 = infinite)")
	)
	err := fs.Parse(args)
	if err != nil {
		panic(err)
	}
	return &testBasic{
		async:       *async,
		concurrency: *concurrency,
		client_a:    getClient(*conf_a),
		client_b:    getClient(*conf_b),
		deployments: *deployments,
		tpl:         template.Must(template.New(`tpl`).Funcs(sprig.FuncMap()).ParseFS(templates, "tpl/*.yml")),
		input: Input{
			Config: Config{
				Crt:     mustRead(*crt),
				Key:     mustRead(*key),
				Kubelet: mustRead(*conf_b),
			},
			Name:     "turbokube-0000",
			Replicas: 16,
			Taint: Taint{
				Key:    "pantopic.com/turbokube",
				Value:  "0000",
				Effect: "NoSchedule",
			},
		},
		n:     *n,
		pause: *pause,
		wg:    &sync.WaitGroup{},
	}
}

func (t *testBasic) Start(ctx context.Context) {
	t.wg.Go(func() {
		t.run(ctx)
	})
}

var patchOpts = metav1.PatchOptions{FieldManager: `kube-controller-manager`}

func (t *testBasic) run(ctx context.Context) {
	// Detect progress
	log.Println(`Detecting progress`)
	var n = t.getProgress(ctx)
	log.Printf("Progress: %d\n", n)

	// Create turbo configmap
	log.Println(`Creating config map`)
	if _, err := t.client_a.CoreV1().ConfigMaps(`default`).
		Patch(ctx, `turbokube`, types.ApplyYAMLPatchType, t.mustRender(`turbo-cm.yml`, t.input), patchOpts); err != nil {
		panic(err)
	}
	log.Println(`Config map created`)
	// Start workers
	var jobs = make(chan int)
	log.Printf("Starting %d Worker(s)\n", t.concurrency)
	for range t.concurrency {
		t.wg.Go(func() {
			t.work(ctx, jobs)
		})
	}
	// Begin iterations
	log.Println(`Begin iterations`)
	for ; n < t.n || t.n == 0; n++ {
		jobs <- n
	}
	log.Println(`Finish iterations`)
	close(jobs)
}

func (t *testBasic) Reset(ctx context.Context) {
	// Delete namespaces
	// Delete nodes
}

func (t *testBasic) Done() (done chan bool) {
	done = make(chan bool)
	go func() {
		t.wg.Wait()
		close(done)
	}()
	return
}

func (t *testBasic) work(ctx context.Context, jobs chan int) {
	for n := range jobs {
		// Create Nodes
		log.Printf("%04x Create Nodes\n", n)
		t.input.Name = fmt.Sprintf(`turbokube-%04x`, n)
		t.input.Taint.Value = fmt.Sprintf(`%04x`, n)
		d, err := t.client_a.AppsV1().Deployments(`default`).
			Patch(ctx, t.input.Name, types.ApplyYAMLPatchType, t.mustRender(`turbo-deploy.yml`, t.input), patchOpts)
		if err != nil {
			panic(err)
		}
		t.awaitDeployment(ctx, t.client_a, d)
		// Create namespace
		log.Printf("%04x Create Namespace\n", n)
		namespace, err := t.client_b.CoreV1().Namespaces().
			Patch(ctx, t.input.Name, types.ApplyYAMLPatchType, t.mustRender(`load-namespace.yml`, t.input), patchOpts)
		if err != nil {
			panic(err)
		}
		// Create deployments
		for i := range t.deployments {
			t.input.Name = fmt.Sprintf(`turbokube-%02x`, i)
			log.Printf("%s Create Deploy %02x\n", t.input.Name, i)
			d, err := t.client_b.AppsV1().Deployments(namespace.Name).
				Patch(ctx, t.input.Name, types.ApplyYAMLPatchType, t.mustRender(`load-deploy.yml`, t.input), patchOpts)
			if err != nil {
				panic(err)
			}
			t.awaitDeployment(ctx, t.client_b, d)
		}
		// Create services
		// Create configmaps
		// Create secrets
		time.Sleep(time.Duration(t.pause) * time.Second)
	}
	log.Printf("Stopping worker\n")
}

func (t *testBasic) mustRender(tpl string, input Input) []byte {
	b := &bytes.Buffer{}
	if err := t.tpl.ExecuteTemplate(b, tpl, input); err != nil {
		panic(err)
	}
	return b.Bytes()
}

func (t *testBasic) getProgress(ctx context.Context) (n int) {
	var err error
	var deploymentList = &appsv1.DeploymentList{}
	for {
		deploymentList, err = t.client_a.AppsV1().Deployments(`default`).
			List(ctx, metav1.ListOptions{
				LabelSelector: `app=turbokube`,
				Continue:      deploymentList.Continue,
			})
		if err != nil {
			panic(err)
		}
		var i int
		for _, d := range deploymentList.Items {
			if _, err := fmt.Sscanf(d.Name, `turbokube-%04x`, &i); err != nil {
				log.Fatalf("%v %s", err, d.Name)
			}
			log.Printf("deploy found: %d", i)
			n = max(i, n)
		}
		if deploymentList.Continue == "" {
			break
		}
	}
	return
}

func (t *testBasic) awaitDeployment(ctx context.Context, client *kubernetes.Clientset, d *appsv1.Deployment) {
	w, err := client.AppsV1().Deployments(d.Namespace).
		Watch(ctx, metav1.ListOptions{
			FieldSelector: `metadata.name=` + d.Name,
		})
	if err != nil {
		panic(err)
	}
	log.Printf("Awaiting deployment %s\n", d.Name)
	for {
		select {
		case e := <-w.ResultChan():
			switch e.Type {
			case watch.Added:
				fallthrough
			case watch.Modified:
				d = e.Object.(*appsv1.Deployment)
				log.Printf("%s %d/%d", e.Type, d.Status.ReadyReplicas, d.Status.Replicas)
				if d.Status.Replicas > 0 && d.Status.ReadyReplicas == d.Status.Replicas {
					return
				}
			case watch.Deleted:
				panic(`Deployment deleted: ` + d.Name)
			case watch.Error:
				panic(`Deployment error: ` + d.Name)
			}
		case <-ctx.Done():
			panic(`Deployment cancelled: ` + d.Name)
		}
	}
}
