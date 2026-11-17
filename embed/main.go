package turbokube

import (
	_ "embed"

	"github.com/pantopic/cluster/iface"
)

const (
	BridgeCron   = "pantopic/turbokube/bridge/cron"
	BridgeLease  = "pantopic/turbokube/bridge/lease"
	ControlBasic = "pantopic/turbokube/control/basic"
	ServiceGrpc  = "pantopic/turbokube/service/grpc"
	StorageKv    = "pantopic/turbokube/storage/kv"
	StorageLease = "pantopic/turbokube/storage/lease"
	Version      = 0
)

func register(c pantopic.ModuleRegistry, wasm ...[]byte) {
	c.RegisterBridge(BridgeCron, wasm[5])
	c.RegisterBridge(BridgeLease, wasm[4])
	c.RegisterControl(ControlBasic, wasm[0])
	c.RegisterService(ServiceGrpc, wasm[1])
	c.RegisterStorage(StorageKv, wasm[2])
	c.RegisterStorage(StorageLease, wasm[3])
}

func Register(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicWasm,
		ServiceGrpcWasm,
		StorageKvWasm,
		StorageLeaseWasm,
		BridgeLeaseWasm,
		BridgeCronWasm,
	)
}

func RegisterDev(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicDevWasm,
		ServiceGrpcDevWasm,
		StorageKvDevWasm,
		StorageLeaseDevWasm,
		BridgeLeaseDevWasm,
		BridgeCronDevWasm,
	)
}

func RegisterZig(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicWasm,
		ServiceGrpcZigWasm,
		StorageKvZigWasm,
		StorageLeaseWasm,
		BridgeLeaseWasm,
		BridgeCronWasm,
	)
}

func RegisterZigDev(c pantopic.ModuleRegistry) {
	register(c,
		ControlBasicDevWasm,
		ServiceGrpcZigDevWasm,
		StorageKvZigDevWasm,
		StorageLeaseDevWasm,
		BridgeLeaseDevWasm,
		BridgeCronDevWasm,
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

//go:embed wasm/bridge-lease.wasm
var BridgeLeaseWasm []byte

//go:embed wasm/bridge-lease.dev.wasm
var BridgeLeaseDevWasm []byte

//go:embed wasm/bridge-cron.wasm
var BridgeCronWasm []byte

//go:embed wasm/bridge-cron.dev.wasm
var BridgeCronDevWasm []byte

/*
//go:embed wasm/bridge-lease.zig.wasm
var BridgeLeaseZigWasm []byte

//go:embed wasm/bridge-lease.zig.dev.wasm
var BridgeLeaseZigDevWasm []byte

//go:embed wasm/bridge-cron.zig.wasm
var BridgeCronZigWasm []byte

//go:embed wasm/bridge-cron.zig.dev.wasm
var BridgeCronZigDevWasm []byte
*/
