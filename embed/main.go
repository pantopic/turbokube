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
	c.RegisterBridge(BridgeCron, wasm[0])
	c.RegisterBridge(BridgeLease, wasm[1])
	c.RegisterControl(ControlBasic, wasm[2])
	c.RegisterService(ServiceGrpc, wasm[3])
	c.RegisterStorage(StorageKv, wasm[4])
	c.RegisterStorage(StorageLease, wasm[5])
}

func Register(c pantopic.ModuleRegistry) {
	register(c,
		BridgeCronWasm,
		BridgeLeaseWasm,
		ControlBasicWasm,
		ServiceGrpcWasm,
		StorageKvWasm,
		StorageLeaseWasm,
	)
}

func RegisterDev(c pantopic.ModuleRegistry) {
	register(c,
		BridgeCronDevWasm,
		BridgeLeaseDevWasm,
		ControlBasicDevWasm,
		ServiceGrpcDevWasm,
		StorageKvDevWasm,
		StorageLeaseDevWasm,
	)
}

func RegisterZig(c pantopic.ModuleRegistry) {
	register(c,
		BridgeCronWasm,
		BridgeLeaseWasm,
		ControlBasicWasm,
		ServiceGrpcZigWasm,
		StorageKvZigWasm,
		StorageLeaseWasm,
	)
}

func RegisterZigDev(c pantopic.ModuleRegistry) {
	register(c,
		BridgeCronDevWasm,
		BridgeLeaseDevWasm,
		ControlBasicDevWasm,
		ServiceGrpcZigDevWasm,
		StorageKvZigDevWasm,
		StorageLeaseDevWasm,
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
