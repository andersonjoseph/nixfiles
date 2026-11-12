package main

import (
	"testing"
)

func TestPlanOpensNewAndClosesGone(t *testing.T) {
	wt := Worktree{Path: "/r/p/feature-1", Project: "p", Branch: "feature-1"}
	mirror := Mirror{WorkspaceID: "w9", CheckoutPath: "/r/p/old-branch"}

	actions := Plan([]Worktree{wt}, []Mirror{mirror}, []string{"/r"})

	if len(actions) != 2 {
		t.Fatalf("want 2 actions, got %+v", actions)
	}
	if actions[0].Kind != ActionOpen || actions[0].Worktree.Path != wt.Path {
		t.Fatalf("want open %s, got %+v", wt.Path, actions[0])
	}
	if actions[1].Kind != ActionClose || actions[1].Mirror.WorkspaceID != "w9" {
		t.Fatalf("want close w9, got %+v", actions[1])
	}
}

func TestPlanNoActionsWhenMatched(t *testing.T) {
	wt := Worktree{Path: "/r/p/feature-1"}
	mirror := Mirror{WorkspaceID: "w1", CheckoutPath: "/r/p/feature-1/", Label: "feature-1"}

	actions := Plan([]Worktree{wt}, []Mirror{mirror}, []string{"/r"})

	if len(actions) != 0 {
		t.Fatalf("want no actions, got %+v", actions)
	}
}

func TestPlanRelabelsStaleLabel(t *testing.T) {
	wt := Worktree{Path: "/r/p/quick-harbor", Branch: "quick-harbor"}
	mirror := Mirror{WorkspaceID: "w4", CheckoutPath: "/r/p/quick-harbor", Label: "samuraiseller/jungle-rabbit · quick-harbor"}

	actions := Plan([]Worktree{wt}, []Mirror{mirror}, []string{"/r"})

	if len(actions) != 1 || actions[0].Kind != ActionRelabel || actions[0].Mirror.WorkspaceID != "w4" {
		t.Fatalf("want relabel w4, got %+v", actions)
	}
}

func TestWorktreeLabel(t *testing.T) {
	if got := (Worktree{Path: "/r/p/quick-harbor", Branch: "quick-harbor"}).label(); got != "quick-harbor" {
		t.Fatalf("want branch label, got %q", got)
	}
	if got := (Worktree{Path: "/r/p/quick-harbor"}).label(); got != "quick-harbor" {
		t.Fatalf("want directory-name fallback, got %q", got)
	}
}

func TestPlanKeepsForeignWorkspaces(t *testing.T) {
	wt := Worktree{Path: "/r/p/feature-1"}
	foreign := Mirror{WorkspaceID: "w2", CheckoutPath: "/elsewhere/plain"}

	actions := Plan([]Worktree{wt}, []Mirror{foreign}, []string{"/r"})

	if len(actions) != 1 || actions[0].Kind != ActionOpen {
		t.Fatalf("want single open, got %+v", actions)
	}
}

func TestPlanClosesLastMirrorInEmptyRoot(t *testing.T) {
	mirror := Mirror{WorkspaceID: "w3", CheckoutPath: "/r/p/gone"}

	actions := Plan(nil, []Mirror{mirror}, []string{"/r"})

	if len(actions) != 1 || actions[0].Kind != ActionClose || actions[0].Mirror.WorkspaceID != "w3" {
		t.Fatalf("want close w3, got %+v", actions)
	}
}
