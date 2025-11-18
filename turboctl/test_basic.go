package main

import (
	"bytes"
	"context"
	"embed"
	"encoding/csv"
	"flag"
	"fmt"
	"log"
	"strconv"
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

var (
	applyOpts  = metav1.PatchOptions{FieldManager: `kube-controller-manager`}
	deleteOpts = metav1.DeleteOptions{}
)

type testBasic struct {
	async       bool
	concurrency int
	csv         *csv.Writer
	deployments int
	client_a    *kubernetes.Clientset
	client_b    *kubernetes.Clientset
	input       Input
	n           int
	pause       int
	out         string
	tpl         *template.Template
	wg          *sync.WaitGroup
}

func newTestBasic(args []string, w *csv.Writer) *testBasic {
	fs := flag.FlagSet{}
	var (
		async       = fs.Bool("async", false, "Do not wait for provisioning")
		concurrency = fs.Int("c", 1, "Concurrency (default 1)")
		conf_a      = fs.String("confa", "/etc/kubernetes/admin.a.conf", "Kubeconfig for cluster A (default /etc/kubernetes/admin.a.conf)")
		conf_b      = fs.String("confb", "/etc/kubernetes/admin.b.conf", "Kubeconfig for cluster B (default /etc/kubernetes/admin.b.conf)")
		crt         = fs.String("crt", "/etc/kubernetes/pki/apiserver.b.crt", "API Server Crt for cluster B (default /etc/kubernetes/pki/apiserver.b.crt)")
		deployments = fs.Int("d", 8, "Number of deployments per namespace (default 8)")
		key         = fs.String("key", "/etc/kubernetes/pki/apiserver.b.key", "API Server Key for cluster B (default /etc/kubernetes/pki/apiserver.b.key)")
		pause       = fs.Int("p", 0, "Pause in seconds between namespace creations (default 0)")
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
			Scheduler: Scheduler{
				Name: "default-scheduler",
			},
			VNodes: 4,
		},
		n:     *n,
		csv:   w,
		pause: *pause,
		wg:    &sync.WaitGroup{},
	}
}

func (t *testBasic) Start(ctx context.Context) {
	t.wg.Go(func() {
		t.run(ctx)
	})
}

func (t *testBasic) run(ctx context.Context) {
	var n = t.getProgress(ctx)
	log.Printf("Progress: %d\n", n)

	log.Println(`Creating turbokube config map`)
	if _, err := t.client_a.CoreV1().ConfigMaps(`default`).
		Patch(ctx, `turbokube`, types.ApplyYAMLPatchType, t.mustRender(`turbo-cm.yml`, t.input), applyOpts); err != nil {
		panic(err)
	}

	if t.concurrency > 1 {
		// https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/
		log.Println(`Creating turbokube scheduler service account`)
		if _, err := t.client_b.CoreV1().ServiceAccounts(`kube-system`).
			Patch(ctx, `turbokube-scheduler`, types.ApplyYAMLPatchType, t.mustRender(`scheduler.serviceaccount.yml`, t.input), applyOpts); err != nil {
			panic(err)
		}
		log.Println(`Creating turbokube scheduler cluster role binding`)
		if _, err := t.client_b.RbacV1().ClusterRoleBindings().
			Patch(ctx, `turbokube-scheduler-as-kube-scheduler`, types.ApplyYAMLPatchType, t.mustRender(`scheduler.clusterrolebinding.yml`, t.input), applyOpts); err != nil {
			panic(err)
		}
		log.Println(`Creating turbokube scheduler role binding`)
		if _, err := t.client_b.RbacV1().RoleBindings(`kube-system`).
			Patch(ctx, `turbokube-scheduler-extension-apiserver-authentication-reader`, types.ApplyYAMLPatchType, t.mustRender(`scheduler.rolebinding.yml`, t.input), applyOpts); err != nil {
			panic(err)
		}
		for i := range t.concurrency {
			t.input.Scheduler.Name = fmt.Sprintf(`turbokube-scheduler-%02x`, i)
			if _, err := t.client_b.CoreV1().ConfigMaps(`kube-system`).
				Patch(ctx, t.input.Scheduler.Name, types.ApplyYAMLPatchType, t.mustRender(`scheduler.configmap.yml`, t.input), applyOpts); err != nil {
				panic(err)
			}
			if _, err := t.client_b.AppsV1().Deployments(`kube-system`).
				Patch(ctx, t.input.Scheduler.Name, types.ApplyYAMLPatchType, t.mustRender(`scheduler.deployment.yml`, t.input), applyOpts); err != nil {
				panic(err)
			}
		}
	}

	log.Printf("Starting %d Worker(s)\n", t.concurrency)
	var jobs = make(chan int)
	for i := range t.concurrency {
		t.wg.Go(func() {
			t.work(ctx, jobs, i)
		})
	}

	log.Println(`Begin work`)
	for ; n < t.n || t.n == 0; n++ {
		name := fmt.Sprintf(`turbokube-%04x`, n)
		var input = t.input
		input.Name = name
		input.Taint.Value = fmt.Sprintf(`%04x`, n)
		_, err := t.client_a.AppsV1().Deployments(`default`).
			Patch(ctx, name, types.ApplyYAMLPatchType, t.mustRender(`turbo-deploy.yml`, input), applyOpts)
		if err != nil {
			panic(err)
		}
		jobs <- n
	}
	close(jobs)
}

func (t *testBasic) Reset(ctx context.Context) {
	var n = t.getProgress(ctx)
	log.Printf("Progress: %d\n", n)

	log.Printf("Starting %d Reset Worker(s)\n", t.concurrency)
	var jobs = make(chan int)
	for range t.concurrency {
		t.wg.Go(func() {
			t.resetWorker(ctx, jobs)
		})
	}

	log.Println(`Begin reset work`)
	for ; n >= 0; n-- {
		jobs <- n
	}
	close(jobs)
}

func (t *testBasic) Done() (done chan bool) {
	done = make(chan bool)
	go func() {
		t.wg.Wait()
		close(done)
	}()
	return
}

func (t *testBasic) work(ctx context.Context, jobs chan int, i int) {
	var base = t.input
	if t.concurrency > 1 {
		base.Scheduler.Name = fmt.Sprintf(`turbokube-scheduler-%02x`, i)
	}
	for n := range jobs {
		name := fmt.Sprintf(`turbokube-%04x`, n)
		var input = base
		input.Name = name
		input.Taint.Value = fmt.Sprintf(`%04x`, n)
		t.awaitDeployment(ctx, t.client_a, `virtual node pool`, `default`, name)
		log.Printf("%s start\n", name)
		namespace, err := t.client_b.CoreV1().Namespaces().
			Patch(ctx, name, types.ApplyYAMLPatchType, t.mustRender(`load-namespace.yml`, input), applyOpts)
		if err != nil {
			panic(err)
		}
		var start = time.Now()
		for i := range t.deployments {
			input.Name = fmt.Sprintf(`turbokube-%02x`, i)
			d, err := t.client_b.AppsV1().Deployments(namespace.Name).
				Patch(ctx, input.Name, types.ApplyYAMLPatchType, t.mustRender(`load-deploy.yml`, input), applyOpts)
			if err != nil {
				panic(err)
			}
			t.awaitDeployment(ctx, t.client_b, `deployment`, d.Namespace, d.Name)
		}
		t.csv.WriteAll([][]string{{name, strconv.Itoa(int(time.Since(start) / time.Millisecond))}})
		// Create services
		// Create configmaps
		// Create secrets
		if t.pause > 0 {
			time.Sleep(time.Duration(t.pause) * time.Second)
		}
	}
	log.Printf("Stopping worker\n")
}

func (t *testBasic) resetWorker(ctx context.Context, jobs chan int) {
	for n := range jobs {
		name := fmt.Sprintf(`turbokube-%04x`, n)
		log.Printf("Deleting namespace %s\n", name)
		err := t.client_b.CoreV1().Namespaces().Delete(ctx, name, deleteOpts)
		if err != nil && !isNotFound(err) {
			log.Fatalf(`%#v`, err)
		}
		log.Printf("Deleting virtual node pool %s\n", name)
		err = t.client_a.AppsV1().Deployments(`default`).Delete(ctx, name, deleteOpts)
		if err != nil && !isNotFound(err) {
			log.Fatalf(`%#v`, err)
		}
		// Delete services
		// Delete configmaps
		// Delete secrets
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
			// log.Printf("deploy found: %d", i)
			n = max(i, n)
		}
		if deploymentList.Continue == "" {
			break
		}
	}
	return
}

func (t *testBasic) awaitDeployment(ctx context.Context, client *kubernetes.Clientset, dtype, namespace, name string) {
	w, err := client.AppsV1().Deployments(namespace).
		Watch(ctx, metav1.ListOptions{
			FieldSelector: `metadata.name=` + name,
		})
	if err != nil {
		panic(err)
	}
	for {
		select {
		case e := <-w.ResultChan():
			switch e.Type {
			case watch.Added:
				fallthrough
			case watch.Modified:
				d := e.Object.(*appsv1.Deployment)
				log.Printf("[%s] %s %s %s %d/%d", namespace, dtype, name, e.Type, d.Status.ReadyReplicas, d.Status.Replicas)
				if d.Status.Replicas > 0 && d.Status.ReadyReplicas == d.Status.Replicas {
					return
				}
			case watch.Deleted:
				panic(`Deployment deleted: ` + name)
			case watch.Error:
				panic(`Deployment error: ` + name)
			}
		case <-ctx.Done():
			panic(`Deployment cancelled: ` + name)
		}
	}
}
