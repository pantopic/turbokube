package turbokube

import (
	_ "embed"

	"github.com/pantopic/cluster/iface"
)

const (
	ControlBasicName = "pantopic/turbokube/control/basic"
	RelayCronName    = "pantopic/turbokube/relay/cron"
	RelayLeaseName   = "pantopic/turbokube/relay/lease"
	ServiceGrpcName  = "pantopic/turbokube/service/grpc"
	StorageKvName    = "pantopic/turbokube/storage/kv"
	StorageLeaseName = "pantopic/turbokube/storage/lease"
	Version          = 0
)

func register(c pantopic.ModuleRegistry, wasm ...[]byte) {
	c.RegisterControl(ControlBasicName, wasm[0])
	c.RegisterService(ServiceGrpcName, wasm[1])
	c.RegisterStorage(StorageKvName, wasm[2])
	c.RegisterStorage(StorageLeaseName, wasm[3])
	c.RegisterRelay(RelayLeaseName, wasm[4])
	c.RegisterRelay(RelayCronName, wasm[5])
}

func Register(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicWasm,
		ServiceGrpcWasm,
		StorageKvWasm,
		StorageLeaseWasm,
		RelayLeaseWasm,
		RelayCronWasm,
	)
}

func RegisterDev(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicDevWasm,
		ServiceGrpcDevWasm,
		StorageKvDevWasm,
		StorageLeaseDevWasm,
		RelayLeaseDevWasm,
		RelayCronDevWasm,
	)
}

func RegisterZig(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicWasm,
		ServiceGrpcZigWasm,
		StorageKvZigWasm,
		StorageLeaseWasm,
		RelayLeaseWasm,
		RelayCronWasm,
	)
}

func RegisterZigDev(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicDevWasm,
		ServiceGrpcZigDevWasm,
		StorageKvZigDevWasm,
		StorageLeaseDevWasm,
		RelayLeaseDevWasm,
		RelayCronDevWasm,
	)
}

//go:embed wasm/control-basic.wasm
var ControlBasicWasm []byte

//go:embed wasm/control-basic.dev.wasm
var ControlBasicDevWasm []byte

//go:embed wasm/service-grpc.wasm
var ServiceGrpcWasm []byte

//go:embed wasm/service-grpc.dev.wasm
var ServiceGrpcDevWasm []byte

//go:embed wasm/storage-kv.wasm
var StorageKvWasm []byte

//go:embed wasm/storage-kv.dev.wasm
var StorageKvDevWasm []byte

//go:embed wasm/storage-lease.wasm
var StorageLeaseWasm []byte

//go:embed wasm/storage-lease.dev.wasm
var StorageLeaseDevWasm []byte

//go:embed wasm/service-grpc.zig.wasm
var ServiceGrpcZigWasm []byte

//go:embed wasm/service-grpc.zig.dev.wasm
var ServiceGrpcZigDevWasm []byte

//go:embed wasm/storage-kv.zig.wasm
var StorageKvZigWasm []byte

//go:embed wasm/storage-kv.zig.dev.wasm
var StorageKvZigDevWasm []byte

//go:embed wasm/relay-lease.wasm
var RelayLeaseWasm []byte

//go:embed wasm/relay-lease.dev.wasm
var RelayLeaseDevWasm []byte

//go:embed wasm/relay-cron.wasm
var RelayCronWasm []byte

//go:embed wasm/relay-cron.dev.wasm
var RelayCronDevWasm []byte

/*
//go:embed wasm/relay-lease.zig.wasm
var RelayLeaseZigWasm []byte

//go:embed wasm/relay-lease.zig.dev.wasm
var RelayLeaseZigDevWasm []byte

//go:embed wasm/relay-cron.zig.wasm
var RelayCronZigWasm []byte

//go:embed wasm/relay-cron.zig.dev.wasm
var RelayCronZigDevWasm []byte
*/
