package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

func main() {
	ctx := context.Background()
	if len(os.Args) < 2 {
		panic("Command required [run, reset]")
	}
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)
	var t Test
	switch os.Args[1] {
	case "run":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			date := strings.ReplaceAll(time.Now().UTC().Format(time.RFC3339), `:`, `-`)
			out := fmt.Sprintf("turbokube.%s.csv", date)
			f, err := os.OpenFile(out, os.O_RDWR|os.O_CREATE, 0644)
			if err != nil {
				log.Fatal(err)
			}
			defer func() {
				if err := f.Close(); err != nil {
					panic(err)
				}
			}()
			w := csv.NewWriter(f)
			w.Write([]string{"sequence", "time (ms)"})
			defer w.Flush()
			t = newTestBasic(args, w)
			t.Start(ctx)
		}
	case "reset":
		args := os.Args[2:]
		switch os.Args[2] {
		case "basic":
			args = os.Args[3:]
			fallthrough
		default:
			t = newTestBasic(args, nil)
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
	case <-t.Done():
	}
	println("done")
}
