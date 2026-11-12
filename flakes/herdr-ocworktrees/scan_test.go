package main

import (
	"os"
	"path/filepath"
	"testing"
)

func writeWorktree(t *testing.T, dir string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, ".git"), []byte("gitdir: /somewhere\n"), 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestScanFindsLinkedWorktrees(t *testing.T) {
	root := t.TempDir()
	writeWorktree(t, filepath.Join(root, "myproject", "feature-42"))
	writeWorktree(t, filepath.Join(root, "other", "nested", "deep-branch"))

	wts, err := Scan([]string{root})
	if err != nil {
		t.Fatal(err)
	}
	if len(wts) != 2 {
		t.Fatalf("want 2 worktrees, got %d: %+v", len(wts), wts)
	}
	byPath := make(map[string]Worktree, len(wts))
	for _, wt := range wts {
		byPath[wt.Path] = wt
	}
	first := byPath[filepath.Join(root, "myproject", "feature-42")]
	if first.Project != "myproject" || first.Branch != "feature-42" {
		t.Fatalf("project/branch mismatch: %+v", first)
	}
	nested := byPath[filepath.Join(root, "other", "nested", "deep-branch")]
	if nested.Project != "other" || nested.Branch != "nested-deep-branch" {
		t.Fatalf("nested project/branch mismatch: %+v", nested)
	}
}

func TestScanSkipsNonWorktrees(t *testing.T) {
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root, "proj", "plain-dir"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, "proj", "primary", ".git"), 0o755); err != nil {
		t.Fatal(err)
	}
	writeWorktree(t, filepath.Join(root, "proj", "wt", "inside"))

	wts, err := Scan([]string{root})
	if err != nil {
		t.Fatal(err)
	}
	if len(wts) != 1 || wts[0].Path != filepath.Join(root, "proj", "wt", "inside") {
		t.Fatalf("want only nested worktree, got %+v", wts)
	}
}

func TestScanMissingRoot(t *testing.T) {
	wts, err := Scan([]string{filepath.Join(t.TempDir(), "nope")})
	if err != nil {
		t.Fatal(err)
	}
	if len(wts) != 0 {
		t.Fatalf("want 0 worktrees, got %+v", wts)
	}
}
