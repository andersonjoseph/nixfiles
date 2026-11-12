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
