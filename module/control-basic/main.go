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
		shardKv, err = cluster.ShardCreate(`kv`, `pantopic/turbokube/storage/kv`,
			cluster.WithTags(component.Tags),
			cluster.WithTag(`pantopic:bridge:kv`, "pantopic/turbokube/bridge/kv"),
			cluster.Persistent())
		if err != nil {
			println(`Failed to create shard kv`, err)
			return cluster.StatusPending
		}
	}
	if _, ok := component.Tags[`turbokube:lease:async`]; ok && shardLease == nil {
		shardLease, err = cluster.ShardCreate(`lease`, `pantopic/turbokube/storage/lease`,
			cluster.WithTags(component.Tags),
			cluster.WithTag(`pantopic:bridge:lease`, "pantopic/turbokube/bridge/lease"),
			cluster.WithTag(`placement:bind`, "kv"),
			cluster.Persistent())
		if err != nil {
			println(`Failed to create shard lease`, err)
			return cluster.StatusPending
		}
	}
	return cluster.StatusActive
}
