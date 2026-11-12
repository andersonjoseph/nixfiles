package main

import (
	"bytes"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestRecentAndMarkRun(t *testing.T) {
	g := NewRunGuard(t.TempDir())

	if g.Recent(debounce) {
		t.Fatal("want not recent before first run")
	}
	g.MarkRun(time.Now())
	if !g.Recent(debounce) {
		t.Fatal("want recent after mark")
	}
	g.MarkRun(time.Now().Add(-time.Hour))
	if g.Recent(debounce) {
		t.Fatal("want not recent after stale mark")
	}
}

func TestNilGuardAllowsRun(t *testing.T) {
	g := NewRunGuard("")

	release, ok := g.Acquire()
	if !ok {
		t.Fatal("want ok for nil guard")
	}
	release()
	if g.Recent(debounce) {
		t.Fatal("nil guard must never debounce")
	}
}

func TestAcquireExcludesConcurrentRun(t *testing.T) {
	dir := t.TempDir()
	first := NewRunGuard(dir)

	release, ok := first.Acquire()
	if !ok {
		t.Fatal("want first acquire ok")
	}
	defer release()

	if _, ok := NewRunGuard(dir).Acquire(); ok {
		t.Fatal("want second acquire to fail while first holds lock")
	}
}

func TestLogLineWrites(t *testing.T) {
	dir := t.TempDir()

	logLine(dir, "open /r/p/b")
	logLine(dir, "close w1 /r/p/b")

	data, err := os.ReadFile(filepath.Join(dir, "sync.log"))
	if err != nil {
		t.Fatal(err)
	}
	if len(data) == 0 || !bytes.Contains(data, []byte("open /r/p/b")) {
		t.Fatalf("bad log content: %q", data)
	}
}
