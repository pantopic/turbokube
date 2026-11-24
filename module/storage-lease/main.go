package main

import (
	"github.com/pantopic/ext-mdb/sdk-go"
	"github.com/pantopic/ext-raft/sdk-go"

	internal "github.com/pantopic/turbokube/module/storage-lease/internal"
)

var (
	epoch    uint64
	newIndex uint64
	txn      mdb.Txn
)

func init() {
	raft.Persistent(open, read, update, commit, abort)
}

func main() {}

func open() (index uint64) {
	if err := mdb.Open(
		mdb.WithMaxDBs(256),
		mdb.WithMaxReaders(256),
		mdb.WithMapSize(256<<30),
	); err != nil {
		panic(`Unable to open env ` + err.Error())
	}
	if err := mdb.Update(func(txn mdb.Txn) (err error) {
		index = dbMeta.init(txn)
		dbLeaseExp.init(txn)
		return nil
	}); err != nil {
		panic(`Unable to open env ` + err.Error())
	}
	return
}

func update(index uint64, cmd []byte) (value uint64, data []byte) {
	newIndex = index
	var err error
	if txn == 0 {
		txn, err = mdb.Begin(0)
		if err != nil {
			panic(`Unable to open txn: ` + err.Error())
		}
		epoch, err = dbMeta.getEpoch(txn)
		if err != nil {
			panic(`Unable to get epoch: ` + err.Error())
		}
	}
	switch cmd[len(cmd)-1] {
	case CMD_LEASE_KEEP_ALIVE:
		var req = &internal.LeaseKeepAliveRequest{}
		if err = req.UnmarshalVT(cmd[:len(cmd)-1]); err != nil {
			data = []byte(`Invalid command: ` + string(cmd))
			return
		}
		res, val, err := cmdLeaseKeepAlive(txn, epoch, req)
		if err != nil {
			panic(`Unable to keep lease alive: ` + err.Error())
		}
		data, err = res.MarshalVT()
		if err != nil {
			panic(`Unable to marshal response: ` + err.Error())
		}
		value = val
	case CMD_LEASE_TICK:
		var req = &internal.LeaseTickRequest{}
		if err = req.UnmarshalVT(cmd[:len(cmd)-1]); err != nil {
			data = []byte(`Invalid command: ` + string(cmd))
			return
		}
		if err = dbMeta.setEpoch(txn, req.Epoch); err != nil {
			panic(`Unable to set epoch: ` + err.Error())
		}
		// Insert Leases
		data, err = (&internal.LeaseTickResponse{}).MarshalVT()
		if err != nil {
			panic(`Unable to marshal response: ` + err.Error())
		}
		value = index
	case CMD_INTERNAL_TERM:
		var req = &internal.TermRequest{}
		if err = req.UnmarshalVT(cmd[:len(cmd)-1]); err != nil {
			data = []byte(`Invalid command: ` + string(cmd))
			return
		}
		term, err := dbMeta.getTerm(txn)
		if err != nil {
			panic(`Unable to get term: ` + err.Error())
		}
		if term > req.Term {
			data = []byte(ErrTermExpired.Error())
			return
		}
		if err = dbMeta.setTerm(txn, req.Term); err != nil {
			panic(`Unable to set term: ` + err.Error())
		}
		data, err = (&internal.TermResponse{}).MarshalVT()
		if err != nil {
			panic(`Unable to marshal response: ` + err.Error())
		}
		value = index
	}
	return
}

func commit() {
	var err error
	if err = dbMeta.setIndex(txn, newIndex); err != nil {
		panic(`Unable to set index: ` + err.Error())
	}
	if err := txn.Commit(); err != nil {
		panic(`Unable to commit transaction: ` + err.Error())
	}
	txn = 0
}

func abort() {
	if txn != 0 {
		txn.Abort()
		txn = 0
	}
}

func read(query []byte) (value uint64, data []byte) {
	var rev uint64
	switch query[len(query)-1] {
	case QUERY_LEASE_TIME_TO_LIVE:
		var req = &internal.LeaseTimeToLiveRequest{}
		if err := req.UnmarshalVT(query[:len(query)-1]); err != nil {
			data = []byte("Invalid query: " + string(query))
			return
		}
		var resp *internal.LeaseTimeToLiveResponse
		err := mdb.View(func(txn mdb.Txn) (err error) {
			resp, err = queryLeaseTimeToLive(txn, req)
			return
		})
		if err != nil {
			data = []byte(err.Error())
			return
		}
		resp.Header = responseHeader(rev)
		data, err = resp.MarshalVT()
		if err != nil {
			data = []byte(err.Error())
			return
		}
		value = 1
	}
	return
}

func cmdLeaseKeepAlive(
	txn mdb.Txn, epoch uint64,
	req *internal.LeaseKeepAliveRequest,
) (res *internal.LeaseKeepAliveResponse, val uint64, err error) {
	res = &internal.LeaseKeepAliveResponse{ID: req.ID}
	var item lease
	if item, err = dbLease.get(txn, uint64(req.ID)); err != nil {
		return
	}
	if item.id == 0 {
		return
	}
	if err = dbLeaseExp.del(txn, item); err != nil {
		return
	}
	res.TTL = int64(item.expires - item.renewed)
	item.expires = epoch + uint64(res.TTL)
	item.renewed = epoch
	if err = dbLease.put(txn, item); err != nil {
		return
	}
	if err = dbLeaseExp.put(txn, item); err != nil {
		return
	}
	val = 1
	return
}

func queryLeaseTimeToLive(
	txn mdb.Txn,
	req *internal.LeaseTimeToLiveRequest,
) (res *internal.LeaseTimeToLiveResponse, err error) {
	res = &internal.LeaseTimeToLiveResponse{}
	epoch, err := dbMeta.getEpoch(txn)
	if err != nil {
		return
	}
	item, err := dbLease.get(txn, uint64(req.ID))
	if err != nil {
		return
	}
	if item.expires > 0 {
		res.TTL = int64(item.expires - epoch)
	} else {
		res.TTL = -1
	}
	return
}

func responseHeader(revision uint64) *internal.ResponseHeader {
	return &internal.ResponseHeader{
		Revision:  int64(revision),
		ClusterId: raft.ShardID,
		MemberId:  raft.ReplicaID,
	}
}
