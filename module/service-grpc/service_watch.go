package main

import (
	"encoding/binary"
	"errors"

	"github.com/pantopic/wazero-buffer-pool/sdk-go"
	"github.com/pantopic/wazero-grpc-server/sdk-go"
	"github.com/pantopic/wazero-shard-client/sdk-go"

	internal "github.com/pantopic/config-bus/module/service-grpc/internal"
)

const (
	BUFFER_POOL_ID_WATCH_EVENT = iota
)

var (
	watchEventBufferSet buffer_pool.MultiValueSet
)

func serviceWatchInit() {
	watchEventBufferSet = buffer_pool.NewMultiValueSet(BUFFER_POOL_ID_WATCH_EVENT,
		buffer_pool.WithSizeLimit(PCB_RESPONSE_SIZE_MAX()))
	grpc_server.NewService(`etcdserverpb.Watch`).
		BidirectionalStream(`Watch`, watchOpen, watchRecv, watchClose)
	shard_client.RegisterStreamRecv(shardRecv)
}

func shardRecv(_, _ []byte, data []byte, id uint64) {
	var err error
	if id == WATCH_ID_ERROR {
		println(`watch err ` + string(data))
		err = errors.New(string(data))
		return
	}
	switch data[0] {
	case WatchMessageType_INIT:
		watchResp.Reset()
		respHeader.Reset()
		if err = respHeader.UnmarshalVT(data[1:]); err != nil {
			panic(`Unable to unmarshal response header: ` + err.Error())
		}
		watchResp.Header = respHeader
		watchResp.WatchId = int64(id)
		watchResp.Created = true
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		// init bufferpool
		grpc_server.Send(data)
	case WatchMessageType_EVENT:
		events := watchEventBufferSet.Find(id)
		if events.Append(data[1:]) {
			return
		}
		var lastRev uint64
		resp := &internal.WatchResponse{
			Header:  &internal.ResponseHeader{},
			WatchId: int64(id),
		}
		for b := range events.Iter() {
			evt := &internal.Event{}
			lastRev = binary.BigEndian.Uint64(b[:8])
			if err = evt.UnmarshalVT(b[8:]); err != nil {
				println(len(b))
				panic(`Unable to unmarshal event: ` + err.Error())
			}
			resp.Events = append(resp.Events, evt)
		}
		currentRev := binary.BigEndian.Uint64(data[1:9])
		if lastRev == currentRev {
			resp.Fragment = true
		}
		resp.Header.Revision = int64(lastRev)
		res, err := resp.MarshalVT()
		if err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(res)
		events.Reset()
		if !events.Append(data[1:]) {
			panic(`Failed to append watch event after reset`)
		}
	case WatchMessageType_SYNC:
		events := watchEventBufferSet.Find(id)
		resp := &internal.WatchResponse{
			Header:  &internal.ResponseHeader{},
			WatchId: int64(id),
		}
		if err = resp.Header.UnmarshalVT(data[1:]); err != nil {
			panic(`Unable to unmarshal response header: ` + err.Error())
		}
		for b := range events.Iter() {
			evt := &internal.Event{}
			println(len(b))
			if err = evt.UnmarshalVT(b[8:]); err != nil {
				panic(`Unable to unmarshal event in sync: ` + err.Error())
			}
			resp.Events = append(resp.Events, evt)
		}
		if data, err = resp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(data)
		events.Reset()
	case WatchMessageType_NOTIFY:
		watchResp.Reset()
		respHeader.Reset()
		if err = respHeader.UnmarshalVT(data[1:]); err != nil {
			panic(`Unable to unmarshal response header: ` + err.Error())
		}
		watchResp.Header = respHeader
		watchResp.WatchId = int64(id)
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(data)
	case WatchMessageType_CANCELED:
		watchResp.Reset()
		watchResp.WatchId = int64(id)
		watchResp.Canceled = true
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		// delete bufferpool
		grpc_server.Send(data)
	case WatchMessageType_ERR_EXISTS:
		watchResp.Reset()
		watchResp.WatchId = -1
		watchResp.Created = true
		watchResp.Canceled = true
		watchResp.CancelReason = ErrWatcherDuplicateID.Error()
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(data)
	case WatchMessageType_ERR_COMPACTED:
		if err = respHeader.UnmarshalVT(data[1:]); err != nil {
			panic(`Unable to unmarshal response header: ` + err.Error())
		}
		watchResp.Reset()
		watchResp.Header = respHeader
		watchResp.WatchId = int64(id)
		watchResp.Created = true
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(data)
		watchResp.Reset()
		watchResp.Header = respHeader
		watchResp.WatchId = int64(id)
		watchResp.Canceled = true
		watchResp.CompactRevision = respHeader.Revision
		if data, err = watchResp.MarshalVT(); err != nil {
			panic(`Unable to marshal watch response: ` + err.Error())
		}
		grpc_server.Send(data)
	default:
		panic(`Unrecognized`)
	}
}

var watchResp = &internal.WatchResponse{
	Header: &internal.ResponseHeader{},
}
var respHeader = &internal.ResponseHeader{}

func watchOpen() (err error) {
	return kvShard().StreamOpen([]byte(`watch`))
}

func watchRecv(data []byte) (err error) {
	return kvShard().StreamSend([]byte(`watch`), data)
}

func watchClose() (err error) {
	return
}
