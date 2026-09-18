package main

import (
	"encoding/binary"

	"github.com/pantopic/ext-mdb/sdk-go"
)

type dbLeaseImpl struct {
	db
}

func (db dbLeaseImpl) init(txn mdb.Txn) {
	db.open(txn)
}

func (db dbLeaseImpl) get(txn mdb.Txn, id uint64) (item lease, err error) {
	k := binary.AppendUvarint(nil, id)
	var v []byte
	v, err = txn.Get(db.i, k, v)
	if mdb.IsNotFound(err) {
		err = nil
		return
	}
	if err != nil {
		return
	}
	return item.FromBytes(k, v)
}

func (db dbLeaseImpl) put(txn mdb.Txn, item lease) error {
	return txn.Put(db.i, binary.AppendUvarint(nil, item.id), item.Bytes(nil), 0)
}

func (db dbLeaseImpl) all(txn mdb.Txn) (items []lease, err error) {
	cur, err := txn.OpenCursor(db.i)
	if err != nil {
		return nil, err
	}
	defer cur.Close()
	var item lease
	var k, v []byte
	k, v, err = cur.Get(k, v, mdb.Next)
	for !mdb.IsNotFound(err) && len(k) > 0 {
		if err != nil {
			return nil, err
		}
		item, err := item.FromBytes(k, v)
		if err != nil {
			return nil, err
		}
		items = append(items, item)
		k, v, err = cur.Get(k[:0], v[:0], mdb.Next)
	}
	if mdb.IsNotFound(err) {
		err = nil
	}
	return
}

func (db dbLeaseImpl) del(txn mdb.Txn, id uint64) error {
	return txn.Del(db.i, binary.AppendUvarint(nil, id), nil)
}
