package main

import (
	"github.com/pantopic/ext-mdb/sdk-go"
)

type dbStatsImpl struct {
	db
}

func (db dbStatsImpl) init(txn mdb.Txn) {
	db.open(txn)
}
