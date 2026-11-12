package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadConfigMissingFileUsesDefault(t *testing.T) {
	cfg, err := LoadConfig(filepath.Join(t.TempDir(), "missing.toml"))
	if err != nil {
		t.Fatal(err)
	}
	home, err := os.UserHomeDir()
	if err != nil {
		t.Fatal(err)
	}
	want := filepath.Join(home, ".local", "share", "opencode", "worktree")
	if len(cfg.Roots) != 1 || cfg.Roots[0] != want {
		t.Fatalf("want default root %s, got %+v", want, cfg.Roots)
	}
}

func TestLoadConfigRoots(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.toml")
	if err := os.WriteFile(path, []byte("roots = [\"~/src/wt\", \"/srv/wt\"]\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	cfg, err := LoadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(cfg.Roots[0], string(os.PathSeparator)) || !strings.HasSuffix(cfg.Roots[0], "src/wt") {
		t.Fatalf("want expanded home root, got %s", cfg.Roots[0])
	}
	if cfg.Roots[1] != "/srv/wt" {
		t.Fatalf("want /srv/wt, got %s", cfg.Roots[1])
	}
}

func TestLoadConfigEmptyRootsUseDefault(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.toml")
	if err := os.WriteFile(path, []byte("roots = []\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	cfg, err := LoadConfig(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Roots) != 1 || cfg.Roots[0] != DefaultConfig().Roots[0] {
		t.Fatalf("want default root, got %+v", cfg.Roots)
	}
}
