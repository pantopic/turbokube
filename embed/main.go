package turbokube

import (
	_ "embed"
)

//go:embed service\-grpc\.wasm
var WasmServiceGrpc []byte

//go:embed storage\-kv\.wasm
var WasmStorageKv []byte
