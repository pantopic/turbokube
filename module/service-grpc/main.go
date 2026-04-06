package main

import (
	"github.com/pantopic/wazero-pipe/sdk-go"
)

const (
	PIPE_ID_LEASE = iota
)

var (
	pipeLease *pipe.Pipe[[]byte]
)

func main() {
	pipeLease = pipe.New[[]byte](pipe.WithID(PIPE_ID_LEASE))
	serviceClusterInit()
	serviceKvInit()
	serviceLeaseInit()
	serviceMaintenanceInit()
	serviceWatchInit()
}
