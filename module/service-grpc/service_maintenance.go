package main

import (
	"github.com/pantopic/wazero-grpc-server/sdk-go"
	"github.com/pantopic/wazero-grpc-server/sdk-go/codes"
	"github.com/pantopic/wazero-grpc-server/sdk-go/status"

	internal "github.com/pantopic/config-bus/module/service-grpc/internal"
)

var (
	statusResp = &internal.StatusResponse{
		Version:     "3.6.5",
		DbSize:      28672,
		DbSizeInUse: 28672,
		IsLearner:   false,
		Header:      &internal.ResponseHeader{},
	}
)

func serviceMaintenanceInit() {
	grpc_server.NewService(`etcdserverpb.Maintenance`).
		Unary(`Alarm`, maintenanceAlarm).
		Unary(`Status`, maintenanceStatus).
		Unary(`Defragment`, maintenanceDefragment).
		Unary(`Hash`, maintenanceHash).
		Unary(`HashKV`, maintenanceHashKV).
		ServerStream(`Snapshot`, maintenanceSnapshotOpen, maintenanceSnapshotClose).
		Unary(`MoveLeader`, maintenanceMoveLeader).
		Unary(`Downgrade`, maintenanceDowngrade)
}

func maintenanceAlarm(in []byte) (err error) {
	return
}

func maintenanceStatus(in []byte) (err error) {
	out, err := grpcError(kvShard().Read(append(in, QUERY_HEADER), false))
	if err != nil {
		return
	}
	err = statusResp.Header.UnmarshalVT(out)
	if err != nil {
		return status.New(codes.Unknown, err.Error()).Err()
	}
	statusResp.Leader = statusResp.Header.MemberId
	statusResp.RaftIndex = uint64(statusResp.Header.Revision)
	statusResp.RaftTerm = 1
	statusResp.RaftAppliedIndex = uint64(statusResp.Header.Revision)
	out, err = statusResp.MarshalVT()
	if err != nil {
		return
	}
	return grpc_server.Send(out)
}

func maintenanceDefragment(in []byte) (err error) {
	return
}

func maintenanceHash(in []byte) (err error) {
	return
}

func maintenanceHashKV(in []byte) (err error) {
	return
}

func maintenanceSnapshotOpen(in []byte) (err error) {
	return
}

func maintenanceSnapshotClose() (err error) {
	return
}

func maintenanceMoveLeader(in []byte) (err error) {
	return
}

func maintenanceDowngrade(in []byte) (err error) {
	return
}
