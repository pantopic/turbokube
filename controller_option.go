package pcb

import (
	"github.com/logbn/zongzi"
)

type ControlOption func(*controller)

func WithLeaseAsync(client zongzi.ShardClient, shard zongzi.Shard) ControlOption {
	return func(c *controller) {
		c.clientLease = client
		c.shardLease = shard
	}
}
