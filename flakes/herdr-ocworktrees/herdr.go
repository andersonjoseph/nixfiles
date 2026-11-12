package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type Herdr struct {
	Bin string
}

func NewHerdr() *Herdr {
	bin := os.Getenv("HERDR_BIN_PATH")
	if bin == "" {
		bin = "herdr"
	}
	return &Herdr{Bin: bin}
}

func (h *Herdr) run(args ...string) ([]byte, error) {
	cmd := exec.Command(h.Bin, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		msg := strings.TrimSpace(stderr.String())
		if msg == "" {
			msg = err.Error()
		}
		return nil, fmt.Errorf("herdr %s: %s", strings.Join(args, " "), msg)
	}
	return stdout.Bytes(), nil
}

type herdrError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func decodeResult(data []byte, out any) error {
	var envelope struct {
		Error  *herdrError     `json:"error"`
		Result json.RawMessage `json:"result"`
	}
	if err := json.Unmarshal(data, &envelope); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}
	if envelope.Error != nil {
		return fmt.Errorf("%s: %s", envelope.Error.Code, envelope.Error.Message)
	}
	if err := json.Unmarshal(envelope.Result, out); err != nil {
		return fmt.Errorf("decode result: %w", err)
	}
	return nil
}

func (h *Herdr) Mirrors() ([]Mirror, error) {
	data, err := h.run("api", "snapshot")
	if err != nil {
		return nil, err
	}
	var parsed struct {
		Snapshot struct {
			Workspaces []struct {
				WorkspaceID string `json:"workspace_id"`
				Worktree    *struct {
					CheckoutPath string `json:"checkout_path"`
				} `json:"worktree"`
			} `json:"workspaces"`
		} `json:"snapshot"`
	}
	if err := decodeResult(data, &parsed); err != nil {
		return nil, err
	}
	var mirrors []Mirror
	for _, w := range parsed.Snapshot.Workspaces {
		if w.Worktree != nil && w.Worktree.CheckoutPath != "" {
			mirrors = append(mirrors, Mirror{
				WorkspaceID:  w.WorkspaceID,
				CheckoutPath: w.Worktree.CheckoutPath,
			})
		}
	}
	return mirrors, nil
}

func (h *Herdr) OpenMirror(wt Worktree) error {
	repo, err := RepoRoot(wt.Path)
	if err != nil {
		return err
	}
	data, err := h.run("worktree", "open", "--cwd", repo, "--path", wt.Path, "--no-focus")
	if err != nil {
		return err
	}
	var opened struct {
		AlreadyOpen bool `json:"already_open"`
		Workspace   struct {
			WorkspaceID string `json:"workspace_id"`
		} `json:"workspace"`
	}
	if err := decodeResult(data, &opened); err != nil {
		return err
	}
	if opened.Workspace.WorkspaceID == "" {
		return nil
	}
	return h.Rename(opened.Workspace.WorkspaceID, labelFor(wt))
}

func (h *Herdr) Close(workspaceID string) error {
	_, err := h.run("workspace", "close", workspaceID)
	return err
}

func (h *Herdr) Rename(workspaceID, label string) error {
	_, err := h.run("workspace", "rename", workspaceID, label)
	return err
}

func (h *Herdr) Notify(body string) {
	if len(body) > 200 {
		body = body[:200]
	}
	_, _ = h.run("notification", "show", "herdr-ocworktrees", "--body", body)
}
