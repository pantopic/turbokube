package main

import (
	"github.com/pantopic/ext-cluster/sdk-go"
	"github.com/pantopic/ext-grpc-server/sdk-go"
	"github.com/pantopic/ext-grpc-server/sdk-go/codes"
	"github.com/pantopic/ext-grpc-server/sdk-go/status"
	"github.com/pantopic/ext-shard-client/sdk-go"
)

var (
	bankName       = []byte(`default`)
	shardNameKv    = []byte(`kv`)
	shardNameLease = []byte(`lease`)
)

func autoSend(out []byte, err error) error {
	if err == nil {
		grpc_server.Send(out)
	} else if grpcErr, ok := err.(*status.Error); ok {
		grpc_server.SendErr(grpcErr.Code(), []byte(grpcErr.Message()))
	} else {
		grpc_server.SendErr(codes.Unknown, []byte(err.Error()))
		// panic(err.Error())
	}
	return err
}

func grpcError(val uint64, out []byte, err error) ([]byte, error) {
	if err == nil && val != 1 {
		if grpcErr, ok := errStringToError[string(out)]; ok {
			err = grpcErr
		} else {
			err = status.New(codes.Unknown, string(out)).Err()
		}
	}
	return out, err
}

func shardKv() shard_client.Client {
	return shard_client.New(bankName, shardNameKv)
}

func shardLease() shard_client.Client {
	return shard_client.New(bankName, shardNameLease)
}

func leaseAsync() bool {
	return cluster.ResourceTagged(`kv`, `turbokube:lease:async`)
}
