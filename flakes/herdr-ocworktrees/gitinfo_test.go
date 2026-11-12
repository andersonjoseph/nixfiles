package main

import (
	"path/filepath"
	"testing"
)

func TestRepoRootResolvesPrimary(t *testing.T) {
	wt := gitFixtureWorktree(t)

	repo, err := RepoRoot(wt.Path)
	if err != nil {
		t.Fatal(err)
	}
	want := filepath.Join(filepath.Dir(filepath.Dir(filepath.Dir(wt.Path))), "repo")
	if repo != want {
		t.Fatalf("want %s, got %s", want, repo)
	}
}

func TestLabelForBranchOnly(t *testing.T) {
	wt := Worktree{Path: "/r/p/quick-harbor", Project: "samuraiseller", Branch: "quick-harbor"}
	if got := labelFor(wt); got != "quick-harbor" {
		t.Fatalf("want branch-only label, got %q", got)
	}
}

func TestLabelForFallsBackToDirName(t *testing.T) {
	wt := Worktree{Path: "/r/p/quick-harbor"}
	if got := labelFor(wt); got != "quick-harbor" {
		t.Fatalf("want directory-name fallback, got %q", got)
	}
}
