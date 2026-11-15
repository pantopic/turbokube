package main

import (
	"github.com/pantopic/ext-cluster/sdk-go/pb"
	"github.com/pantopic/ext-relay/sdk-go"
	// "github.com/pantopic/ext-shard-client/sdk-go"
)

func init() {
	relay.Init(start, reload, stop)
}

func main() {
}

func start(term uint64, shard *pb.Shard) {
	println("relay-cron start")
}

func reload(term uint64, shard *pb.Shard) {
	println("relay-cron reload")
}

func stop(term uint64, shard *pb.Shard) {
	println("relay-cron stop")
}
