package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

const maxDepth = 3

type Worktree struct {
	Path    string
	Project string
	Branch  string
}

func Scan(roots []string) ([]Worktree, error) {
	var found []Worktree
	for _, root := range roots {
		root = filepath.Clean(root)
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return nil
			}
			if !d.IsDir() {
				return nil
			}
			rel, err := filepath.Rel(root, path)
			if err != nil {
				return nil
			}
			if rel == "." {
				return nil
			}
			if isLinkedWorktree(path) {
				parts := strings.Split(rel, string(filepath.Separator))
				found = append(found, Worktree{
					Path:    path,
					Project: parts[0],
					Branch:  strings.Join(parts[1:], "-"),
				})
				return fs.SkipDir
			}
			if strings.Count(rel, string(filepath.Separator)) >= maxDepth-1 {
				return fs.SkipDir
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	return found, nil
}

func isLinkedWorktree(path string) bool {
	info, err := os.Stat(filepath.Join(path, ".git"))
	return err == nil && !info.IsDir()
}
