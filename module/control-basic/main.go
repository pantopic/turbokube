package main

import (
	"strings"

	"github.com/pantopic/ext-cluster/sdk-go"
	"github.com/pantopic/ext-cluster/sdk-go/pb"
)

func init() {
	cluster.Init(
		cluster.WithComponentReconciler(reconcile),
	)
}

func main() {
}

func reconcile(component *pb.Component) uint32 {
	var err error
	var shardKv *pb.Shard
	var shardLease *pb.Shard
	for s := range cluster.ShardIter() {
		switch s.Name[strings.LastIndex(s.Name, `.`)+1:] {
		case `kv`:
			shardKv = s
		case `lease`:
			shardLease = s
		}
	}
	if shardKv == nil {
		shardKv, err = cluster.ShardCreatePersistent(&pb.Shard{Name: `kv`},
			cluster.WithTag(`pantopic:module`, "pantopic/turbokube/storage/kv"),
			// cluster.WithTag(`pantopic:relay:cron`, "pantopic/turbokube/relay/cron"),
		)
		if err != nil {
			println(`Failed to create shard kv`, err)
			return cluster.StatusPending
		}
	}
	if cluster.ResourceTagged(`turbokube:lease:async`) {
		if shardLease == nil {
			// _, err := cluster.ShardCreatePersistent(&pb.Shard{Name: `lease`},
			// 	cluster.WithTag(`pantopic:module`, "pantopic/turbokube/storage/lease"),
			// 	cluster.WithTag(`pantopic:relay:lease`, "pantopic/turbokube/relay/lease"),
			// 	cluster.WithTag(`placement:bind`, "kv"))
			// if err != nil {
			// 	println(`Failed to create shard lease`, err)
			// 	return cluster.StatusPending
			// }
		}
	}
	return cluster.StatusActive
}
