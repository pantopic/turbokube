package main

import (
	"github.com/pantopic/ext-grpc-server/sdk-go"

	internal "github.com/pantopic/turbokube/module/service-grpc/internal"
)

var (
	statusResp = &internal.StatusResponse{
		Version:     "3.6.5",
		DbSize:      28672,
		DbSizeInUse: 28672,
		IsLearner:   false,
		Header:      &internal.ResponseHeader{},
	}
	alarmResp = &internal.AlarmResponse{
		Header: &internal.ResponseHeader{},
	}
)

func maintenanceAlarm(in []byte) (err error) {
	out, err := alarmResp.MarshalVT()
	if err != nil {
		return
	}
	return grpc_server.Send(out)
}

func maintenanceStatus(in []byte) (err error) {
	kvShard().ReadAsync([]byte(`maintenanceStatus`), append(in, QUERY_HEADER), false)
	return
}

func maintenanceDefragment(in []byte) (err error) {
	return grpc_server.Send(nil)
}

func maintenanceHash(in []byte) (err error) {
	return grpc_server.Send(nil)
}

func maintenanceHashKV(in []byte) (err error) {
	return grpc_server.Send(nil)
}

func maintenanceSnapshotOpen(in []byte) (err error) {
	return grpc_server.Send(nil)
}

func maintenanceSnapshotClose() (err error) {
	return grpc_server.Send(nil)
}

func maintenanceMoveLeader(in []byte) (err error) {
	return grpc_server.Send(nil)
}

func maintenanceDowngrade(in []byte) (err error) {
	return grpc_server.Send(nil)
}
