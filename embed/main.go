package turbokube

import (
	_ "embed"
)

const (
	ControlBasicName = "pantopic/turbokube/control/basic"
	ServiceGrpcName  = "pantopic/turbokube/service/grpc"
	StorageKvName    = "pantopic/turbokube/storage/kv"
	StorageLeaseName = "pantopic/turbokube/storage/lease"
	Version          = 0
)

type runtime interface {
	Register(name string, wasm []byte)
}

type cluster interface {
	RuntimeControl() runtime
	RuntimeService() runtime
	RuntimeStorage() runtime
	RuntimeRelay() runtime
}

func Register(c cluster) {
	c.RuntimeControl().Register(ControlBasicName, ControlBasicDevWasm)
	c.RuntimeService().Register(ServiceGrpcName, ServiceGrpcDevWasm)
	c.RuntimeStorage().Register(StorageKvName, StorageKvDevWasm)
	c.RuntimeStorage().Register(StorageLeaseName, StorageLeaseDevWasm)
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
