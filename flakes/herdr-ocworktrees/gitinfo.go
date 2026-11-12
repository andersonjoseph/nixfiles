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

func RemoteSlug(worktree string) string {
	url, err := gitOut(worktree, "remote", "get-url", "origin")
	if err != nil {
		return ""
	}
	return slugFromRemote(url)
}

func slugFromRemote(url string) string {
	if strings.HasPrefix(url, "/") {
		return ""
	}
	url = strings.TrimSuffix(url, ".git")
	if i := strings.Index(url, "://"); i >= 0 {
		url = url[i+3:]
	} else if i := strings.Index(url, ":"); i >= 0 {
		url = url[:i] + "/" + url[i+1:]
	}
	parts := strings.Split(strings.Trim(url, "/"), "/")
	if len(parts) < 2 {
		return ""
	}
	return parts[len(parts)-2] + "/" + parts[len(parts)-1]
}

func labelFor(wt Worktree, repoRoot string) string {
	branch := wt.Branch
	if branch == "" {
		branch = filepath.Base(wt.Path)
	}
	if slug := RemoteSlug(wt.Path); slug != "" {
		return slug + " · " + branch
	}
	if base := filepath.Base(repoRoot); base != "" && base != "." && base != "/" {
		return base + " · " + branch
	}
	if wt.Project != "" {
		return wt.Project + " · " + branch
	}
	return branch
}
