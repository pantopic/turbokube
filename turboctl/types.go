package main

import (
	"context"
)

type Test interface {
	Start(ctx context.Context)
	Reset(ctx context.Context)
	Stop()
	Done() (done chan bool)
}

type Taint struct {
	Effect string
	Key    string
	Value  string
}

type Config struct {
	Crt     string
	Key     string
	Kubelet string
}

type Input struct {
	Config   Config
	Name     string
	Replicas int
	Taint    Taint
}
