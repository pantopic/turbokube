//! Mirrors module/storage-kv/db_stats.go

const mdb = @import("mdb");

const Db = @import("db.zig").Db;

pub const DbStats = struct {
    db: Db,

    pub fn init(self: DbStats, txn: mdb.Txn) void {
        self.db.open(txn);
    }
};
