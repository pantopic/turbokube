package main

import (
	"strings"
	"testing"

	"github.com/andreyvit/diff"
)

func TestBasic(t *testing.T) {
	b := newTestBasic([]string{
		"--confa=test/kubelet.conf.yml",
		"--confb=test/kubelet.conf.yml",
		"--crt=test/apiserver.crt",
		"--key=test/apiserver.key",
	})
	observed := strings.TrimSpace(string(b.mustRender(`turbo-cm.yml`, b.input)))
	expected := strings.TrimSpace(mustRead(`test/turbo-cm.expected.yml`))
	if observed != expected {
		t.Fatalf("Unexpected: \n%s", diff.LineDiff(observed, expected))
	}
}
