package main

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
)

type Config struct {
	Roots []string `toml:"roots"`
}

func DefaultConfig() Config {
	return Config{Roots: []string{ExpandHome("~/.local/share/opencode/worktree")}}
}

func LoadConfig(path string) (Config, error) {
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return DefaultConfig(), nil
	}
	if err != nil {
		return Config{}, err
	}
	var cfg Config
	if _, err := toml.Decode(string(data), &cfg); err != nil {
		return Config{}, err
	}
	if len(cfg.Roots) == 0 {
		return DefaultConfig(), nil
	}
	for i, root := range cfg.Roots {
		cfg.Roots[i] = ExpandHome(root)
	}
	return cfg, nil
}

func ExpandHome(path string) string {
	if path == "~" || strings.HasPrefix(path, "~/") {
		home, err := os.UserHomeDir()
		if err == nil {
			return filepath.Join(home, strings.TrimPrefix(path, "~"))
		}
	}
	return path
}
