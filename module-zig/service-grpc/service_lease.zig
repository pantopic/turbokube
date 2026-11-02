//! Mirrors module/service-grpc/service_lease.go

const types = @import("types.zig");
const util = @import("util.zig");

pub fn grant(in: []const u8) anyerror!void {
    return util.kvShard().ApplyAsync("leaseGrant", util.withSuffix(in, types.CMD_LEASE_GRANT));
}

pub fn revoke(in: []const u8) anyerror!void {
    return util.kvShard().ApplyAsync("leaseRevoke", util.withSuffix(in, types.CMD_LEASE_REVOKE));
}

pub fn keepaliveOpen() anyerror!void {}

pub fn keepaliveRecv(in: []const u8) anyerror!void {
    return util.kvShard().ApplyAsync("leaseKeepAlive", util.withSuffix(in, types.CMD_LEASE_KEEP_ALIVE));
}

pub fn keepaliveClose() anyerror!void {}

pub fn leases(in: []const u8) anyerror!void {
    return util.kvShard().ReadAsync("leaseLeases", util.withSuffix(in, types.QUERY_LEASE_LEASES), true);
}

pub fn timeToLive(in: []const u8) anyerror!void {
    return util.kvShard().ReadAsync("leaseTimeToLive", util.withSuffix(in, types.QUERY_LEASE_TIME_TO_LIVE), true);
}
