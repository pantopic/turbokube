package main

import (
	"encoding/binary"
	"strconv"

	"github.com/pantopic/ext-mdb/sdk-go"
)

var (
	dbMeta  = dbMetaImpl{db{`meta`, 2, mdb.Create}}
	dbStats = dbStatsImpl{db{`stats`, 3, mdb.Create}}
	kvStore = kvStoreImpl{
		rev: db{`revision`, 4, mdb.Create | mdb.DupSort},
		evt: db{`event`, 5, mdb.Create | mdb.DupSort},
		val: db{`value`, 6, mdb.Create},
	}
	dbLease    = dbLeaseImpl{db{`lease`, 7, mdb.Create}}
	dbLeaseExp = dbLeaseExpImpl{db{`lease_exp`, 8, mdb.Create}}
	dbLeaseKey = dbLeaseKeyImpl{db{`lease_key`, 9, mdb.Create}}
)

type db struct {
	name  string
	i     mdb.DBI
	flags uint32
}

func (db db) open(txn mdb.Txn) {
	i, err := txn.OpenDBI(db.name, db.flags)
	if err != nil {
		panic(err)
	}
	if i != db.i {
		panic("Incorrect DBI: " + db.name + "(" + strconv.Itoa(int(i)) + ")")
	}
}

func (db db) trimChecksum(key, val []byte) ([]byte, error) {
	if len(val) < 4 {
		return nil, ErrChecksumInvalid
	}
	chk := binary.BigEndian.Uint32(val[len(val)-4:])
	val = val[:len(val)-4]
	if chk != crc(key, val) {
		return nil, ErrChecksumInvalid
	}
	return val, nil
}

func (db db) addChecksum(key, val []byte) []byte {
	return binary.BigEndian.AppendUint32(val, crc(key, val))
}

func (db db) getUint64(txn mdb.Txn, key []byte) (i uint64, err error) {
	var val []byte
	val, err = txn.Get(db.i, key, val)
	if err != nil {
		return
	}
	val, err = db.trimChecksum(key, val)
	if err != nil {
		return
	}
	if len(val) < 8 {
		err = ErrValueInvalid
	}
	i = binary.BigEndian.Uint64(val[:8])
	return
}

func (db db) putUint64(txn mdb.Txn, key []byte, val uint64) (err error) {
	return txn.Put(db.i, key, db.addChecksum(key, binary.BigEndian.AppendUint64(nil, val)), 0)
}
