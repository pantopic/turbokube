package main

import (
	"github.com/pantopic/wazero-grpc-server/sdk-go"
	"github.com/pantopic/wazero-grpc-server/sdk-go/codes"

	internal "github.com/pantopic/turbokube/module/service-grpc/internal"
)

var (
	rangeRequest = &internal.RangeRequest{}
)

func kvRange(in []byte) (err error) {
	err = rangeRequest.UnmarshalVT(in)
	if err != nil {
		grpc_server.SendErr(codes.InvalidArgument, []byte(err.Error()))
		return
	}
	return autoSend(grpcError(kvShard().Read(append(in, QUERY_KV_RANGE), rangeRequest.Serializable)))
}

func kvPut(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_KV_PUT))))
}

func kvDeleteRange(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_KV_DELETE_RANGE))))
}

func kvTxn(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_KV_TXN))))
}

func kvCompact(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_KV_COMPACT))))
}
