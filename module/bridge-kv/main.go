package main

import (
	"time"

	"github.com/pantopic/ext-bridge/sdk-go"
	"github.com/pantopic/ext-cluster/sdk-go/pb"
	"github.com/pantopic/ext-cron/sdk-go"
)

func init() {
	bridge.Init(start, reload, stop)
	cron.Init(callback)
}

var (
	name = []byte(`cron`)
)

func main() {}

func start(term uint64, shard *pb.Shard) {
	println("bridge-cron start")
	cron.Start(name, time.Second)
}

func reload(term uint64, shard *pb.Shard) {
	println("bridge-cron reload")
}

func stop(term uint64, shard *pb.Shard) {
	println("bridge-cron stop")
	cron.Stop(name)
}

func callback(name []byte) {
	println("cron tick")
}
