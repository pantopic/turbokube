package main

import (
	"errors"

	"github.com/aperturerobotics/protobuf-go-lite"
)

type (
	Message protobuf_go_lite.Message
)

const (
	KV_FLAG_PATCH uint8 = 1 << iota
	KV_FLAG_COMPRESSED
)

const (
	CMD_INTERNAL_TERM byte = iota
	CMD_INTERNAL_TICK
	CMD_KV_COMPACT
	CMD_KV_DELETE_RANGE
	CMD_KV_PUT
	CMD_KV_TXN
	CMD_LEASE_EXPIRE
	CMD_LEASE_GRANT
	CMD_LEASE_KEEP_ALIVE
	CMD_LEASE_KEEP_ALIVE_BATCH
	CMD_LEASE_REVOKE
	CMD_LEASE_TICK
)

const (
	QUERY_HEADER byte = iota
	QUERY_KV_RANGE
	QUERY_LEASE_EXISTS
	QUERY_LEASE_LEASES
	QUERY_LEASE_TIME_TO_LIVE
	QUERY_WATCH_PROGRESS
)

const (
	WatchMessageType__UNKNOWN byte = iota
	WatchMessageType_CANCELED
	WatchMessageType_ERR_COMPACTED
	WatchMessageType_ERR_EXISTS
	WatchMessageType_EVENT_BATCH
	WatchMessageType_EVENT_SYNC
	WatchMessageType_INIT
	WatchMessageType_NOTIFY
)

var (
	ErrChecksumInvalid = errors.New(`Checksum invalid`)
	ErrChecksumMissing = errors.New(`Checksum missing`)
	ErrValueInvalid    = errors.New(`Value invalid`)
	ErrPatchInvalid    = errors.New(`Patch invalid (missing next?)`)
	ErrKeyInvalid      = errors.New(`Key invalid`)
	ErrKeyMissing      = errors.New(`Key missing`)
	ErrLeaseKeyInvalid = errors.New(`Lease key invalid`)
	ErrNotFound        = errors.New(`Not found`)
	ErrTermExpired     = errors.New(`Term expired`)
)
