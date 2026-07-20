package turbokube

import (
	_ "embed"
)

const (
	ServiceGrpcName = "pantopic/turbokube/service/grpc"
	StorageKvName   = "pantopic/turbokube/storage/kv"
	Version         = 0
)

//go:embed service\-grpc\.wasm
var ServiceGrpcWasm []byte

//go:embed service\-grpc\.dev\.wasm
var ServiceGrpcDevWasm []byte

//go:embed storage\-kv\.wasm
var StorageKvWasm []byte

//go:embed storage\-kv\.dev\.wasm
var StorageKvDevWasm []byte
