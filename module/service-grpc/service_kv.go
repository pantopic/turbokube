package main

import (
	"github.com/pantopic/ext-grpc-server/sdk-go"
	"github.com/pantopic/ext-grpc-server/sdk-go/codes"

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
	kvShard().ReadAsync([]byte("kvRange"), append(in, QUERY_KV_RANGE), rangeRequest.Serializable)
	return
}

func kvPut(in []byte) (err error) {
	kvShard().ApplyAsync([]byte("kvPut"), append(in, CMD_KV_PUT))
	return
}

func kvDeleteRange(in []byte) (err error) {
	kvShard().ApplyAsync([]byte("kvDeleteRange"), append(in, CMD_KV_DELETE_RANGE))
	return
}

func kvTxn(in []byte) (err error) {
	kvShard().ApplyAsync([]byte("kvTxn"), append(in, CMD_KV_TXN))
	return
}

func kvCompact(in []byte) (err error) {
	kvShard().ApplyAsync([]byte("kvCompact"), append(in, CMD_KV_COMPACT))
	return
}
