package main

import (
	"context"
	_ "embed"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/PowerDNS/lmdb-go/lmdb"
	"github.com/logbn/zongzi"
	"github.com/soheilhy/cmux"
	"github.com/tetratelabs/wazero"
	"github.com/tetratelabs/wazero/api"
	"github.com/tetratelabs/wazero/imports/wasi_snapshot_preview1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/keepalive"

	"github.com/pantopic/wazero-atomic/host"
	"github.com/pantopic/wazero-buffer-pool/host"
	"github.com/pantopic/wazero-global/host"
	"github.com/pantopic/wazero-grpc-server/host"
	"github.com/pantopic/wazero-lmdb/host"
	"github.com/pantopic/wazero-pool"
	"github.com/pantopic/wazero-range-watch/host"
	"github.com/pantopic/wazero-shard-client/host"
	"github.com/pantopic/wazero-small-cache/host"
	"github.com/pantopic/wazero-state-machine/host"

	"github.com/pantopic/turbokube"
)

const (
	PCB_STATE_MACHINE_WASM = true
)

//go:embed service\-grpc\.wasm
var wasmServiceGrpc []byte

//go:embed storage\-kv\.wasm
var wasmStorageKv []byte

type extStorage interface {
	wazero_state_machine.ContextCopier
	Register(context.Context, wazero.Runtime) error
	InitContext(context.Context, api.Module) (context.Context, error)
}

type extService interface {
	wazero_grpc_server.ContextCopier
	Register(context.Context, wazero.Runtime) error
	InitContext(context.Context, api.Module) (context.Context, error)
}

func main() {
	zongzi.SetLogLevel(zongzi.LogLevelInfo)
	var cfg = getConfig()
	var ctx = context.Background()
	var log = slog.Default()
	var ctrl = pcb.NewController(ctx, log)
	agent, err := zongzi.NewAgent(cfg.ClusterName, strings.Split(cfg.HostPeers, ","),
		zongzi.WithDirRaft(cfg.Dir+"/raft"),
		zongzi.WithDirWAL(cfg.Dir+"/wal"),
		zongzi.WithHostTags(cfg.GetHostTags()...),
		zongzi.WithAddrGossip(fmt.Sprintf("%s:%d", cfg.HostName, cfg.PortGossip)),
		zongzi.WithAddrRaft(fmt.Sprintf("%s:%d", cfg.HostName, cfg.PortRaft)),
		zongzi.WithAddrApi(fmt.Sprintf("%s:%d", cfg.HostName, cfg.PortZongzi)),
		zongzi.WithHostMemoryLimit(zongzi.HostMemory256),
		zongzi.WithRaftEventListener(ctrl))
	if err != nil {
		panic(err)
	}
	hostModGlobal := wazero_global.New()
	if !PCB_STATE_MACHINE_WASM {
		agent.StateMachineRegister(pcb.Uri, pcb.NewStateMachineFactory(log, cfg.Dir+"/data"))
	} else {
		runtimeStorageKv := wazero.NewRuntimeWithConfig(ctx, wazero.NewRuntimeConfig())
		wasi_snapshot_preview1.MustInstantiate(ctx, runtimeStorageKv)
		hostModLMDB := wazero_lmdb.New()
		storageExtensions := []extStorage{
			hostModLMDB,
			hostModGlobal,
			wazero_atomic.New(),
			wazero_range_watch.New(),
			wazero_small_cache.New(),
			wazero_state_machine.New(),
		}
		var storageContextCopiers []wazero_state_machine.ContextCopier
		for _, m := range storageExtensions {
			if err = m.Register(ctx, runtimeStorageKv); err != nil {
				panic(err)
			}
			storageContextCopiers = append(storageContextCopiers, wazero_state_machine.ContextCopier(m))
		}
		poolStorageKv, err := wazeropool.New(ctx, runtimeStorageKv, wasmStorageKv,
			wazeropool.WithModuleConfig(wazero.NewModuleConfig().WithStdout(os.Stdout)),
			wazeropool.WithLimit(runtime.NumCPU()))
		if err != nil {
			panic(err)
		}
		ctx = wazeropool.ContextSet(ctx, poolStorageKv)
		poolStorageKv.Run(func(mod api.Module) {
			for _, m := range storageExtensions {
				if ctx, err = m.InitContext(ctx, mod); err != nil {
					panic(err)
				}
			}
		})
		poolFactoryStorage := func(shardID uint64) wazeropool.Instance {
			return poolStorageKv
		}
		ctx = hostModLMDB.RegisterEnv(ctx, getEnv(cfg))
		agent.StateMachineRegister(pcb.Uri, wazero_state_machine.FactoryPersistent(ctx,
			zongzi.GetLogger(`statemachine`),
			poolFactoryStorage,
			storageContextCopiers...,
		))
		go func() {
			for {
				time.Sleep(5 * time.Second)
				if stats := poolStorageKv.Stats(); stats.Active > 0 {
					log.Info("poolStorageKv.Stats", "total", stats.Total,
						"avgMemSize", stats.MemSize/max(stats.Total, 1), "memMax", stats.MemMax, "memMin", stats.MemMin,
						"active", stats.Active/max(stats.Total, 1), "actMax", stats.ActMax, "actMin", stats.ActMin,
					)
				}
			}
		}()
	}
	if err = agent.Start(ctx); err != nil {
		panic(err)
	}
	// TODO - Replace shard create with resource create
	shard, _, err := agent.ShardCreate(ctx, pcb.Uri,
		zongzi.WithName("default.pcb.kv"),
		zongzi.WithPlacementMembers(3, `pantopic:turbokube=member`),
		zongzi.WithPlacementCover(`pantopic:turbokube=nonvoting`))
	if err != nil {
		panic(err)
	}
	if err = agent.ReplicaAwait(ctx, 30*time.Second, shard.ID); err != nil {
		panic(err)
	}
	if err = ctrl.Start(agent.Client(shard.ID), shard); err != nil {
		panic(err)
	}

	// gRPC server
	var opts = []grpc.ServerOption{
		grpc.KeepaliveEnforcementPolicy(keepalive.EnforcementPolicy{
			MinTime:             5 * time.Second,
			PermitWithoutStream: false,
		}),
		grpc.KeepaliveParams(keepalive.ServerParameters{
			Time:    2 * time.Hour,
			Timeout: 20 * time.Second,
		}),
	}
	if cfg.TlsCrt != "" && cfg.TlsKey != "" {
		fc, err := credentials.NewServerTLSFromFile(cfg.TlsCrt, cfg.TlsKey)
		if err != nil {
			panic(err)
		}
		opts = append(opts, grpc.Creds(fc))
	}
	var grpcServer = grpc.NewServer(opts...)

	// Create Runtime
	runtimeServiceGrpc := wazero.NewRuntimeWithConfig(ctx, wazero.NewRuntimeConfig())
	wasi_snapshot_preview1.MustInstantiate(ctx, runtimeServiceGrpc)
	hostModGrpcServer := wazero_grpc_server.New()
	serviceExtensions := []extService{
		hostModGlobal,
		hostModGrpcServer,
		wazero_buffer_pool.New(),
		wazero_shard_client.New(agent),
	}
	var serviceContextCopiers []wazero_grpc_server.ContextCopier
	for _, m := range serviceExtensions {
		if err = m.Register(ctx, runtimeServiceGrpc); err != nil {
			panic(err)
		}
		serviceContextCopiers = append(serviceContextCopiers, m)
	}
	poolServiceGrpc, err := wazeropool.New(ctx, runtimeServiceGrpc, wasmServiceGrpc,
		wazeropool.WithModuleConfig(wazero.NewModuleConfig().WithStdout(os.Stdout)),
		wazeropool.WithLimit(runtime.NumCPU()))
	if err != nil {
		panic(err)
	}
	ctx = wazeropool.ContextSet(ctx, poolServiceGrpc)
	poolServiceGrpc.Run(func(mod api.Module) {
		for _, m := range serviceExtensions {
			if ctx, err = m.InitContext(ctx, mod); err != nil {
				panic(err)
			}
		}
	})
	serviceContextCopiers = append(serviceContextCopiers, wazero_shard_client.NewResolver(`default`, `pcb`))
	if err = hostModGrpcServer.RegisterServices(ctx, grpcServer, poolServiceGrpc, serviceContextCopiers...); err != nil {
		panic(err)
	}
	go func() {
		for {
			time.Sleep(5 * time.Second)
			if stats := poolServiceGrpc.Stats(); stats.Active > 0 {
				log.Info("poolServiceGrpc.Stats", "total", stats.Total,
					"avgMemSize", stats.MemSize/max(stats.Total, 1), "memMax", stats.MemMax, "memMin", stats.MemMin,
					"active", stats.Active/max(stats.Total, 1), "actMax", stats.ActMax, "actMin", stats.ActMin,
				)
			}
		}
	}()

	// Run gRPC and HTTP servers
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.PortApi))
	if err != nil {
		panic(err)
	}
	m := cmux.New(lis)
	grpcListener := m.Match(cmux.HTTP2())
	httpListener := m.Match(cmux.Any())
	go func() {
		if err = grpcServer.Serve(grpcListener); err != nil {
			panic(err)
		}
	}()
	httpServer := &http.Server{
		Handler: pcb.NewEndpointHandler(grpcServer),
	}
	go func() {
		if cfg.TlsCrt != "" && cfg.TlsKey != "" {
			if err = httpServer.ServeTLS(httpListener, cfg.TlsCrt, cfg.TlsKey); err != nil {
				panic(err)
			}
		} else {
			if err = httpServer.Serve(httpListener); err != nil {
				panic(err)
			}
		}
	}()
	go func() {
		if err := m.Serve(); err != nil {
			panic(err)
		}
	}()

	// await stop
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	signal.Notify(stop, syscall.SIGTERM)
	<-stop

	if grpcServer != nil {
		var ch = make(chan bool)
		go func() {
			grpcServer.GracefulStop()
			close(ch)
		}()
		select {
		case <-ch:
		case <-time.After(5 * time.Second):
			grpcServer.Stop()
		}
	}
	agent.Stop()
}

func getEnv(cfg config) *lmdb.Env {
	err := os.MkdirAll(cfg.Dir, 0700)
	if err != nil {
		panic(err)
	}
	env, err := lmdb.NewEnv()
	if err != nil {
		panic(err)
	}
	env.SetMaxDBs(255)
	env.SetMapSize(int64(64 << 30)) // 64 GiB
	env.SetMaxReaders(1 << 16)      // 64k readers
	if err = env.Open(cfg.Dir+`/data.mdb`, uint(lmdb.NoMemInit|lmdb.NoSync|lmdb.NoMetaSync|lmdb.NoSubdir), 0700); err != nil {
		panic(err)
	}
	return env
}
