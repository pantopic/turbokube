package main

func leaseGrant(in []byte) (err error) {
	shardKv().ApplyAsync([]byte("leaseGrant"), append(in, CMD_LEASE_GRANT))
	return
}

func leaseRevoke(in []byte) (err error) {
	if leaseAsync() {
		shardLease().ApplyAsync([]byte("leaseRevokeExternal"), append(in, CMD_LEASE_REVOKE))
	} else {
		shardKv().ApplyAsync([]byte("leaseRevoke"), append(in, CMD_LEASE_REVOKE))
	}
	return
}

func leaseKeepaliveOpen() (err error) {
	return
}

func leaseKeepaliveRecv(item []byte) (err error) {
	if leaseAsync() {
		shardLease().ApplyAsync([]byte("leaseKeepaliveRecvAsync"), append(item, CMD_LEASE_KEEP_ALIVE))
	} else {
		shardKv().ApplyAsync([]byte(`leaseKeepaliveRecv`), append(item, CMD_LEASE_KEEP_ALIVE))
	}
	return
}

func leaseKeepaliveClose() (err error) {
	return
}

func leaseLeases(in []byte) (err error) {
	shardKv().ReadAsync([]byte(`leaseLeases`), append(in, QUERY_LEASE_LEASES), false)
	return
}

func leaseTimeToLive(in []byte) (err error) {
	if leaseAsync() {
		shardLease().ReadAsync([]byte("leaseTimeToLive"), append(in, QUERY_LEASE_TIME_TO_LIVE), false)
	} else {
		shardKv().ReadAsync([]byte(`leaseTimeToLive`), append(in, QUERY_LEASE_TIME_TO_LIVE), false)
	}
	return
}
