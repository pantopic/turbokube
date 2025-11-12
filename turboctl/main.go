package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	if len(os.Args) < 2 {
		panic("Command required [run, reset]")
	}
	var t Test
	switch os.Args[1] {
	case "run":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			t = newTestBasic(args)
			t.Start(ctx)
		}
	case "reset":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			t = newTestBasic(args)
			t.Reset(ctx)
		}
	}

	// await stop
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt)
	signal.Notify(stop, syscall.SIGTERM)
	select {
	case <-stop:
		fmt.Println(`stopping`)
		cancel()
		t.Stop()
	case <-t.Done():
	}

	println("done")
}
