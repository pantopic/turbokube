package turbokube

import (
	_ "embed"
)

const (
	NameServiceGrpc = "pantopic/turbokube/service/grpc"
	NameStorageKv   = "pantopic/turbokube/storage/kv"
)

//go:embed service\-grpc\.wasm
var WasmServiceGrpc []byte

//go:embed service\-grpc\.dev\.wasm
var WasmServiceGrpcDev []byte

//go:embed storage\-kv\.wasm
var WasmStorageKv []byte

//go:embed storage\-kv\.dev\.wasm
var WasmStorageKvDev []byte
