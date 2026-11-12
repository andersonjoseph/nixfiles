package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

const debounce = 2 * time.Second

const maxLogSize = 1 << 20

type RunGuard struct {
	dir string
}

func NewRunGuard(dir string) *RunGuard {
	if dir == "" {
		return nil
	}
	return &RunGuard{dir: dir}
}

func (g *RunGuard) Acquire() (func(), bool) {
	if g == nil {
		return func() {}, true
	}
	if err := os.MkdirAll(g.dir, 0o755); err != nil {
		return func() {}, true
	}
	f, err := os.OpenFile(filepath.Join(g.dir, "sync.lock"), os.O_CREATE|os.O_RDWR, 0o644)
	if err != nil {
		return func() {}, true
	}
	if err := syscall.Flock(int(f.Fd()), syscall.LOCK_EX|syscall.LOCK_NB); err != nil {
		f.Close()
		return nil, false
	}
	return func() {
		_ = syscall.Flock(int(f.Fd()), syscall.LOCK_UN)
		_ = f.Close()
	}, true
}

func (g *RunGuard) Recent(within time.Duration) bool {
	if g == nil {
		return false
	}
	data, err := os.ReadFile(filepath.Join(g.dir, "last-run"))
	if err != nil {
		return false
	}
	ms, err := strconv.ParseInt(strings.TrimSpace(string(data)), 10, 64)
	if err != nil {
		return false
	}
	return time.Since(time.UnixMilli(ms)) < within
}

func (g *RunGuard) MarkRun(now time.Time) {
	if g == nil {
		return
	}
	_ = os.WriteFile(filepath.Join(g.dir, "last-run"), []byte(strconv.FormatInt(now.UnixMilli(), 10)), 0o644)
}

func logLine(stateDir, msg string) {
	if stateDir == "" {
		return
	}
	path := filepath.Join(stateDir, "sync.log")
	if info, err := os.Stat(path); err == nil && info.Size() > maxLogSize {
		_ = os.Remove(path)
	}
	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0o644)
	if err != nil {
		return
	}
	defer f.Close()
	fmt.Fprintf(f, "%s %s\n", time.Now().Format(time.RFC3339), msg)
}
