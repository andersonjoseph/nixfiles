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

func TestRemoteSlug(t *testing.T) {
	wt := gitFixtureWorktree(t)

	if slug := RemoteSlug(wt.Path); slug != "acme/api" {
		t.Fatalf("want acme/api, got %q", slug)
	}
}

func TestSlugFromRemote(t *testing.T) {
	cases := map[string]string{
		"https://github.com/acme/api.git":     "acme/api",
		"https://github.com/acme/api":         "acme/api",
		"git@github.com:acme/api.git":         "acme/api",
		"ssh://git@github.com/acme/api.git":   "acme/api",
		"https://gitlab.com/grp/sub/acme/api": "acme/api",
		"/local/checkout/api":                 "",
		"weird":                               "",
	}
	for url, want := range cases {
		if got := slugFromRemote(url); got != want {
			t.Fatalf("slugFromRemote(%q) = %q, want %q", url, got, want)
		}
	}
}

func TestLabelForFallsBackToRepoName(t *testing.T) {
	wt := Worktree{Path: filepath.Join(t.TempDir(), "someproject", "fix"), Project: "someproject", Branch: "fix"}
	if got := labelFor(wt, "/srv/checkouts/myrepo"); got != "myrepo · fix" {
		t.Fatalf("want repo-name fallback label, got %q", got)
	}
}

func TestLabelForFallsBackToProject(t *testing.T) {
	wt := Worktree{Path: filepath.Join(t.TempDir(), "someproject", "fix"), Project: "someproject", Branch: "fix"}
	if got := labelFor(wt, ""); got != "someproject · fix" {
		t.Fatalf("want project fallback label, got %q", got)
	}
}
