package main

import (
	"path/filepath"
	"strings"
)

type ActionKind int

const (
	ActionOpen ActionKind = iota
	ActionClose
)

type Mirror struct {
	WorkspaceID  string
	CheckoutPath string
}

type Action struct {
	Kind     ActionKind
	Worktree Worktree
	Mirror   Mirror
}

func (a Action) String() string {
	if a.Kind == ActionOpen {
		return "open " + a.Worktree.Path
	}
	return "close " + a.Mirror.WorkspaceID + " " + a.Mirror.CheckoutPath
}

func Plan(scanned []Worktree, mirrors []Mirror, roots []string) []Action {
	openByPath := make(map[string]Mirror, len(mirrors))
	for _, m := range mirrors {
		openByPath[filepath.Clean(m.CheckoutPath)] = m
	}
	scannedPaths := make(map[string]bool, len(scanned))
	var actions []Action
	for _, wt := range scanned {
		scannedPaths[wt.Path] = true
		if _, ok := openByPath[wt.Path]; !ok {
			actions = append(actions, Action{Kind: ActionOpen, Worktree: wt})
		}
	}
	for _, m := range mirrors {
		path := filepath.Clean(m.CheckoutPath)
		if scannedPaths[path] {
			continue
		}
		if !underAnyRoot(path, roots) {
			continue
		}
		actions = append(actions, Action{Kind: ActionClose, Mirror: m})
	}
	return actions
}

func underAnyRoot(path string, roots []string) bool {
	for _, root := range roots {
		rel, err := filepath.Rel(filepath.Clean(root), path)
		if err == nil && rel != ".." && !strings.HasPrefix(rel, "../") {
			return true
		}
	}
	return false
}
