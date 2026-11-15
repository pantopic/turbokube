package main

import (
	"github.com/pantopic/ext-mdb/sdk-go"
)

var (
	// Logical clock representing seconds of uptime since shard creation
	metaKeyEpoch = []byte(`epoch`)

	// Index of last applied raft log entry
	metaKeyIndex = []byte(`index`)

	// Autoincrement cursor for generating lease ids
	metaKeyLeaseID = []byte(`lease_id`)

	// Shard raft term - Prevents duplicate controllers
	metaKeyTerm = []byte(`term`)
)

type dbMetaImpl struct {
	db
}

func (db dbMetaImpl) init(txn mdb.Txn) (index uint64) {
	var err error
	db.open(txn)
	for _, k := range [][]byte{
		metaKeyEpoch,
		metaKeyIndex,
		metaKeyLeaseID,
		metaKeyTerm,
	} {
		if _, err = db.db.getUint64(txn, k); mdb.IsNotFound(err) {
			err = db.putUint64(txn, k, 0)
		}
		if err != nil {
			panic(err)
		}
	}
	if index, err = db.getIndex(txn); err != nil {
		panic(err)
	}
	return
}

func (db dbMetaImpl) getEpoch(txn mdb.Txn) (val uint64, err error) {
	return db.getUint64(txn, metaKeyEpoch)
}

func (db dbMetaImpl) setEpoch(txn mdb.Txn, val uint64) (err error) {
	return db.putUint64(txn, metaKeyEpoch, val)
}

func (db dbMetaImpl) getIndex(txn mdb.Txn) (val uint64, err error) {
	return db.getUint64(txn, metaKeyIndex)
}

func (db dbMetaImpl) setIndex(txn mdb.Txn, val uint64) (err error) {
	return db.putUint64(txn, metaKeyIndex, val)
}

func (db dbMetaImpl) getLeaseID(txn mdb.Txn) (val uint64, err error) {
	return db.getUint64(txn, metaKeyLeaseID)
}

func (db dbMetaImpl) setLeaseID(txn mdb.Txn, val uint64) (err error) {
	return db.putUint64(txn, metaKeyLeaseID, val)
}

func (db dbMetaImpl) getTerm(txn mdb.Txn) (val uint64, err error) {
	return db.getUint64(txn, metaKeyTerm)
}

func (db dbMetaImpl) setTerm(txn mdb.Txn, val uint64) (err error) {
	return db.putUint64(txn, metaKeyTerm, val)
}
