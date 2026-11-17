package main

import (
	"github.com/pantopic/ext-bridge/sdk-go"
	"github.com/pantopic/ext-cluster/sdk-go/pb"
	// "github.com/pantopic/ext-shard-client/sdk-go"
)

func init() {
	bridge.Init(start, reload, stop)
}

func main() {
}

func start(term uint64, shard *pb.Shard) {
	println("bridge-lease start")
}

func reload(term uint64, shard *pb.Shard) {
	println("bridge-lease reload")
}

func stop(term uint64, shard *pb.Shard) {
	println("bridge-lease stop")
}
