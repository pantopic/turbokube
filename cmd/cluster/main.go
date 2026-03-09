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
	"github.com/pantopic/wazero-global/host"
	"github.com/pantopic/wazero-grpc-server/host"
	"github.com/pantopic/wazero-lmdb/host"
	"github.com/pantopic/wazero-pipe/host"
	"github.com/pantopic/wazero-pool"
	"github.com/pantopic/wazero-range-watch/host"
	"github.com/pantopic/wazero-shard-client/host"
	"github.com/pantopic/wazero-small-cache/host"
	"github.com/pantopic/wazero-state-machine/host"

	"github.com/pantopic/config-bus"
)

const (
	PCB_STATE_MACHINE_WASM = true
)

//go:embed service\-grpc\.wasm
var wasmServiceGrpc []byte

//go:embed storage\-kv\.wasm
var wasmStorageKv []byte

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
	if !PCB_STATE_MACHINE_WASM {
		agent.StateMachineRegister(pcb.Uri, pcb.NewStateMachineFactory(log, cfg.Dir+"/data"))
	} else {
		runtimeStorageKv := wazero.NewRuntimeWithConfig(ctx, wazero.NewRuntimeConfig())
		wasi_snapshot_preview1.MustInstantiate(ctx, runtimeStorageKv)
		var (
			hostModAtomic       = wazero_atomic.New()
			hostModGlobal       = wazero_global.New()
			hostModLMDB         = wazero_lmdb.New()
			hostModRangeWatch   = wazero_range_watch.New()
			hostModSmallCache   = wazero_small_cache.New()
			hostModStateMachine = wazero_state_machine.New()
		)
		if err = hostModAtomic.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		if err = hostModGlobal.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		if err = hostModStateMachine.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		if err = hostModLMDB.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		if err = hostModRangeWatch.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		if err = hostModSmallCache.Register(ctx, runtimeStorageKv); err != nil {
			panic(err)
		}
		poolStorageKv, err := wazeropool.New(ctx, runtimeStorageKv, wasmStorageKv,
			wazeropool.WithModuleConfig(wazero.NewModuleConfig().WithStdout(os.Stdout)))
		if err != nil {
			panic(err)
		}
		ctx = wazeropool.ContextSet(ctx, poolStorageKv)
		poolStorageKv.Run(func(mod api.Module) {
			if ctx, err = hostModAtomic.InitContext(ctx, mod); err != nil {
				panic(err)
			}
			if ctx, err = hostModGlobal.InitContext(ctx, mod); err != nil {
				panic(err)
			}
			if ctx, err = hostModStateMachine.InitContext(ctx, mod); err != nil {
				panic(err)
			}
			if ctx, err = hostModLMDB.InitContext(ctx, mod); err != nil {
				panic(err)
			}
			if ctx, err = hostModRangeWatch.InitContext(ctx, mod); err != nil {
				panic(err)
			}
			if ctx, err = hostModSmallCache.InitContext(ctx, mod); err != nil {
				panic(err)
			}
		})
		poolFactoryStorage := func(shardID uint64) wazeropool.Instance {
			return poolStorageKv
		}
		ctx = hostModLMDB.RegisterEnv(ctx, getEnv(cfg))
		agent.StateMachineRegister(pcb.Uri, wazero_state_machine.FactoryPersistent(
			ctx,
			zongzi.GetLogger(`statemachine`),
			poolFactoryStorage,
			hostModAtomic.ContextCopy,
			hostModGlobal.ContextCopy,
			hostModLMDB.ContextCopy,
			hostModRangeWatch.ContextCopy,
			hostModSmallCache.ContextCopy,
			hostModStateMachine.ContextCopy,
			wazeropool.ContextCopy,
		))
	}
	if err = agent.Start(ctx); err != nil {
		panic(err)
	}
	// TODO - Replace shard create with resource create
	shard, _, err := agent.ShardCreate(ctx, pcb.Uri,
		zongzi.WithName("default.pcb.kv"),
		zongzi.WithPlacementMembers(3, `pantopic/config-bus=member`),
		zongzi.WithPlacementCover(`pantopic/config-bus=nonvoting`))
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
	var (
		hostModGlobal      = wazero_global.New()
		hostModGrpcServer  = wazero_grpc_server.New()
		hostModPipe        = wazero_pipe.New()
		hostModShardClient = wazero_shard_client.New(agent,
			wazero_shard_client.WithNamespace(`default`),
			wazero_shard_client.WithResource(`pcb`),
		)
	)
	if err = hostModGlobal.Register(ctx, runtimeServiceGrpc); err != nil {
		panic(err)
	}
	if err = hostModGrpcServer.Register(ctx, runtimeServiceGrpc); err != nil {
		panic(err)
	}
	if err = hostModPipe.Register(ctx, runtimeServiceGrpc); err != nil {
		panic(err)
	}
	if err = hostModShardClient.Register(ctx, runtimeServiceGrpc); err != nil {
		panic(err)
	}
	poolServiceGrpc, err := wazeropool.New(ctx, runtimeServiceGrpc, wasmServiceGrpc, wazeropool.WithModuleConfig(wazero.NewModuleConfig().
		WithStdout(os.Stdout)))
	if err != nil {
		panic(err)
	}
	ctx = wazeropool.ContextSet(ctx, poolServiceGrpc)
	poolServiceGrpc.Run(func(mod api.Module) {
		if ctx, err = hostModGlobal.InitContext(ctx, mod); err != nil {
			panic(err)
		}
		if ctx, err = hostModPipe.InitContext(ctx, mod); err != nil {
			panic(err)
		}
		if ctx, err = hostModGrpcServer.InitContext(ctx, mod); err != nil {
			panic(err)
		}
		if ctx, err = hostModShardClient.InitContext(ctx, mod); err != nil {
			panic(err)
		}
	})
	if err = hostModGrpcServer.RegisterServices(ctx, grpcServer, poolServiceGrpc,
		hostModGlobal.ContextCopy,
		hostModGrpcServer.ContextCopy,
		hostModPipe.ContextCopy,
		hostModShardClient.ContextCopy,
		wazeropool.ContextCopy,
	); err != nil {
		panic(err)
	}

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
