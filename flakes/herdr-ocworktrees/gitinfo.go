package main

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
)

func gitOut(dir string, args ...string) (string, error) {
	cmd := exec.Command("git", append([]string{"-C", dir}, args...)...)
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func RepoRoot(worktree string) (string, error) {
	gitDir, err := gitOut(worktree, "rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return "", fmt.Errorf("resolve repo root: %w", err)
	}
	return filepath.Dir(gitDir), nil
}
