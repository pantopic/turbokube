package main

import (
	"context"
	_ "embed"
	"log/slog"
	"net/http"
	_ "net/http/pprof"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/logbn/zongzi"

	"github.com/pantopic/cluster"
	"github.com/pantopic/cluster/pb"

	"github.com/pantopic/turbokube/embed"
)

var (
	port = 19000
)

func main() {
	go func() {
		slog.Info("pprof server", "err", http.ListenAndServe(":6060", nil))
	}()
	zongzi.SetLogLevel(zongzi.LogLevelInfo)
	var ctx = context.Background()
	var cfg = cluster.EnvConfig(
		cluster.WithEnvPrefix("PCB_"),
		cluster.WithDefault(cluster.Config{
			ClusterName: "pcb",
			Dir:         "/var/lib/pantopic/turbokube",
			HostName:    "pcb-0",
			HostPeers:   "pcb-0:17001,pcb-1:17001,pcb-2:17001",
			HostTags:    "cluster:host|cluster:member|host:class=storage",
			LogLevel:    "info",
			PortApi:     17000,
			PortZongzi:  17001,
			PortRaft:    17002,
			PortGossip:  17003,
		}),
	)
	os.MkdirAll(cfg.Dir, 01777)
	host := cluster.New(ctx, cfg)
	turbokube.RegisterDev(host)
	if err := host.Start(); err != nil {
		panic(err)
	}
	defer host.Stop()
	ctrlClient := host.ControlClient()
	// 10 seconds for namespaces to be created
	var err error
	await(10, 100, func() bool {
		resp, err := ctrlClient.NamespaceGet(ctx, &pb.NamespaceGetRequest{
			Name: "default",
		})
		return err == nil && resp != nil && resp.Item != nil && resp.Item.Name == `default`
	})
	resource := &pb.Resource{
		Namespace: "default",
		Name:      "turbokube-test",
		Type:      "pantopic/turbokube",
	}
	service := &pb.Service{
		Namespace: resource.Namespace,
		Resource:  resource.Name,
		Cluster:   cfg.ClusterName,
		Name:      "api",
		Type:      "grpc",
		Port:      uint64(port),
		Status:    cluster.Status_Active,
		Tags: map[string]string{
			"placement:cover": "cluster:host",
		},
	}
	component := &pb.Component{
		Namespace: resource.Namespace,
		Resource:  resource.Name,
		Cluster:   cfg.ClusterName,
		Name:      "default",
		Type:      "basic",
		Tags: map[string]string{
			"placement:member": "3;host:class=storage",
			// "placement:vary":   "geo:zone",
		},
	}
	if _, err = ctrlClient.ResourcePut(ctx, &pb.ResourcePutRequest{
		Item: resource,
	}); err != nil {
		panic(err)
	}
	if _, err = ctrlClient.ServicePut(ctx, &pb.ServicePutRequest{
		Item: service,
	}); err != nil {
		panic(err)
	}
	if _, err = ctrlClient.ComponentPut(ctx, &pb.ComponentPutRequest{
		Item: component,
	}); err != nil {
		panic(err)
	}
	await(10, 100, func() bool {
		svcListReq := &pb.ServiceListRequest{
			Namespace: resource.Namespace,
			Resource:  resource.Name,
		}
		var svcListResp *pb.ServiceListResponse
		svcListResp, err = ctrlClient.ServiceList(ctx, svcListReq)
		return err == nil &&
			svcListResp.Code == cluster.ResultSuccess &&
			len(svcListResp.Item) > 0 &&
			svcListResp.Item[0].Status == cluster.Status_Active
	})
	await(10, 100, func() bool {
		compListReq := &pb.ComponentListRequest{
			Namespace: resource.Namespace,
			Resource:  resource.Name,
		}
		var compListResp *pb.ComponentListResponse
		compListResp, err = ctrlClient.ComponentList(ctx, compListReq)
		return err == nil &&
			compListResp.Code == cluster.ResultSuccess &&
			len(compListResp.Item) > 0 &&
			compListResp.Item[0].Status == cluster.Status_Active
	})

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	signal.Notify(stop, syscall.SIGTERM)
	<-stop
}

func await(d, n time.Duration, fn func() bool) bool {
	for i := 0; i < int(n); i++ {
		if fn() {
			return true
		}
		time.Sleep(d * time.Second / n)
	}
	return false
}
