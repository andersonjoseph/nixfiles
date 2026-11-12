package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: herdr-ocworktrees sync")
		os.Exit(2)
	}
	switch os.Args[1] {
	case "sync":
		if err := runSync(os.Stdout, os.Stderr); err != nil {
			fmt.Fprintln(os.Stderr, "herdr-ocworktrees:", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintln(os.Stderr, "unknown command:", os.Args[1])
		os.Exit(2)
	}
}

func runSync(stdout, stderr io.Writer) error {
	stateDir := os.Getenv("HERDR_PLUGIN_STATE_DIR")
	guard := NewRunGuard(stateDir)
	release, ok := guard.Acquire()
	if !ok {
		return nil
	}
	defer release()
	if guard.Recent(debounce) {
		return nil
	}
	defer guard.MarkRun(time.Now())

	cfg, err := LoadConfig(configPath())
	if err != nil {
		return err
	}
	worktrees, err := Scan(cfg.Roots)
	if err != nil {
		return err
	}
	herdr := NewHerdr()
	mirrors, err := herdr.Mirrors()
	if err != nil {
		return err
	}
	var failures []string
	for _, action := range Plan(worktrees, mirrors, cfg.Roots) {
		var err error
		if action.Kind == ActionOpen {
			err = herdr.OpenMirror(action.Worktree)
		} else {
			err = herdr.Close(action.Mirror.WorkspaceID)
		}
		if err != nil {
			failures = append(failures, action.String()+": "+err.Error())
			continue
		}
		fmt.Fprintln(stdout, action)
		logLine(stateDir, action.String())
	}
	if len(failures) > 0 {
		herdr.Notify(strings.Join(failures, "; "))
		for _, failure := range failures {
			fmt.Fprintln(stderr, failure)
		}
	}
	return nil
}

func configPath() string {
	dir := os.Getenv("HERDR_PLUGIN_CONFIG_DIR")
	if dir == "" {
		return "config.toml"
	}
	return filepath.Join(dir, "config.toml")
}
