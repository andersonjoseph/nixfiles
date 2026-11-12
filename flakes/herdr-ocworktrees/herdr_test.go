package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func stubHerdr(t *testing.T, script string) *Herdr {
	t.Helper()
	path := filepath.Join(t.TempDir(), "herdr-stub")
	if err := os.WriteFile(path, []byte("#!/bin/sh\n"+script), 0o755); err != nil {
		t.Fatal(err)
	}
	return &Herdr{Bin: path}
}

func TestMirrorsParsesSnapshot(t *testing.T) {
	h := stubHerdr(t, `echo '{"result":{"snapshot":{"workspaces":[{"workspace_id":"w1","label":"stale · /r/a","worktree":{"checkout_path":"/r/a"}},{"workspace_id":"w2"},{"workspace_id":"w3","label":"b","worktree":{"checkout_path":"/r/b"}}]}}}'`)

	mirrors, err := h.Mirrors()
	if err != nil {
		t.Fatal(err)
	}
	if len(mirrors) != 2 {
		t.Fatalf("want 2 mirrors, got %+v", mirrors)
	}
	if mirrors[0].WorkspaceID != "w1" || mirrors[0].CheckoutPath != "/r/a" || mirrors[0].Label != "stale · /r/a" {
		t.Fatalf("bad first mirror: %+v", mirrors[0])
	}
	if mirrors[1].WorkspaceID != "w3" || mirrors[1].CheckoutPath != "/r/b" {
		t.Fatalf("bad second mirror: %+v", mirrors[1])
	}
}

func TestMirrorsReturnsHerdrError(t *testing.T) {
	h := stubHerdr(t, `echo '{"error":{"code":"not_found","message":"no session"}}'`)

	if _, err := h.Mirrors(); err == nil || !strings.Contains(err.Error(), "no session") {
		t.Fatalf("want herdr error, got %v", err)
	}
}

func gitFixtureWorktree(t *testing.T) Worktree {
	t.Helper()
	root := t.TempDir()
	repo := filepath.Join(root, "repo")
	git := func(args ...string) {
		t.Helper()
		cmd := exec.Command("git", append([]string{"-C", repo, "-c", "commit.gpgsign=false", "-c", "user.name=t", "-c", "user.email=t@t"}, args...)...)
		if out, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("git %v: %v: %s", args, err, out)
		}
	}
	if out, err := exec.Command("git", "init", "-b", "main", repo).CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, out)
	}
	git("commit", "--allow-empty", "-m", "init")
	git("remote", "add", "origin", "https://github.com/acme/api.git")
	wt := filepath.Join(root, "worktree", "acme", "feature-9")
	git("worktree", "add", wt, "-b", "feature-9")
	return Worktree{Path: wt, Project: "acme", Branch: "feature-9"}
}

func TestOpenMirrorOpensAndRenames(t *testing.T) {
	wt := gitFixtureWorktree(t)
	argsFile := filepath.Join(t.TempDir(), "args.log")
	t.Setenv("STUB_ARGS_FILE", argsFile)
	h := stubHerdr(t, `
echo "$@" >> "$STUB_ARGS_FILE"
if [ "$1 $2" = "worktree open" ]; then
  echo '{"result":{"already_open":false,"workspace":{"workspace_id":"wNEW"}}}'
else
  echo '{"result":{"type":"workspace_info"}}'
fi
`)

	if err := h.OpenMirror(wt); err != nil {
		t.Fatal(err)
	}
	args, err := os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	calls := string(args)
	if !strings.Contains(calls, "worktree open --cwd") || !strings.Contains(calls, wt.Path) {
		t.Fatalf("missing worktree open call: %s", calls)
	}
	if !strings.Contains(calls, "workspace rename wNEW") || !strings.Contains(calls, "feature-9") {
		t.Fatalf("missing rename call: %s", calls)
	}
}

func TestOpenMirrorRenamesWhenAlreadyOpen(t *testing.T) {
	wt := gitFixtureWorktree(t)
	argsFile := filepath.Join(t.TempDir(), "args.log")
	t.Setenv("STUB_ARGS_FILE", argsFile)
	h := stubHerdr(t, `
echo "$@" >> "$STUB_ARGS_FILE"
echo '{"result":{"already_open":true,"workspace":{"workspace_id":"wOLD"}}}'
`)

	if err := h.OpenMirror(wt); err != nil {
		t.Fatal(err)
	}
	args, err := os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(args), "workspace rename wOLD feature-9") {
		t.Fatalf("want relabel of already-open mirror: %s", args)
	}
}
