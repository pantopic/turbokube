package turbokube

import (
	_ "embed"
)

//go:embed service\-grpc\.wasm
var WasmServiceGrpc []byte

//go:embed service\-grpc\.dev\.wasm
var WasmServiceGrpcDev []byte

//go:embed storage\-kv\.wasm
var WasmStorageKv []byte

//go:embed storage\-kv\.dev\.wasm
var WasmStorageKvDev []byte
