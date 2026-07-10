package turbokube

//go:embed service\-grpc\.wasm
var WasmServiceGrpc []byte

//go:embed storage\-kv\.wasm
var WasmStorageKv []byte
