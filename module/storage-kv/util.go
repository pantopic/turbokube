package main

import (
	internal "github.com/pantopic/config-bus/module/storage-kv/internal"
)

func txnIntCompare(cond internal.Compare_CompareResult, a, b int64) bool {
	switch cond {
	case internal.Compare_EQUAL:
		return a == b
	case internal.Compare_GREATER:
		return a > b
	case internal.Compare_LESS:
		return a < b
	case internal.Compare_NOT_EQUAL:
		return a != b
	}
	return false
}
