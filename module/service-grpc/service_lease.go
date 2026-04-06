package main

import (
	"github.com/pantopic/wazero-grpc-server/sdk-go"
)

func serviceLeaseInit() {
	grpc_server.NewService(`etcdserverpb.Lease`).
		Unary(`LeaseGrant`, leaseGrant).
		Unary(`LeaseRevoke`, leaseRevoke).
		BidirectionalStream(`LeaseKeepAlive`, leaseKeepaliveOpen, leaseKeepaliveRecv, leaseKeepaliveClose).
		Unary(`LeaseLeases`, leaseLeases).
		Unary(`LeaseTimeToLive`, leaseTimeToLive)
}

func leaseGrant(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_LEASE_GRANT))))
}

func leaseRevoke(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(in, CMD_LEASE_REVOKE))))
}

func leaseKeepaliveOpen() (err error) {
	return
}

func leaseKeepaliveRecv(item []byte) (err error) {
	return autoSend(grpcError(kvShard().Apply(append(item, CMD_LEASE_KEEP_ALIVE))))
}

func leaseKeepaliveClose() (err error) {
	return
}

func leaseLeases(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Read(append(in, QUERY_LEASE_LEASES), true)))
}

func leaseTimeToLive(in []byte) (err error) {
	return autoSend(grpcError(kvShard().Read(append(in, QUERY_LEASE_TIME_TO_LIVE), true)))
}
