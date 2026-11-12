# herdr-ocworktrees

A [herdr](https://herdr.dev) plugin that mirrors git worktrees created by
[OpenCode](https://opencode.ai) into herdr workspaces, so they show up in the
sidebar and stay in sync as OpenCode creates and deletes them.

OpenCode stores its worktrees under
`~/.local/share/opencode/worktree/<project-id>/<branch>/`, outside your
repository, with no way to customize the location. This plugin watches that
folder and keeps herdr's workspace list aligned with it:

- a new worktree directory is opened as a herdr workspace (`worktree open` by
  path, grouped under the repository, labelled `owner/repo · branch` when a
  git remote exists, otherwise `<project-id> · <branch>`)
- when the directory disappears, the mirrored workspace is closed, together
  with its panes and processes
- workspaces without worktree provenance, and worktrees outside the configured
  roots, are never touched

Sync runs on herdr server startup, on workspace/tab/pane focus and creation
events, and on demand through the `sync` action. Every run is a stateless
diff over the current snapshot, guarded by a lock and a debounce.

## Requirements

- herdr 0.9.5 or later
- git 2.31 or later
- Go 1.26 or later (only to build)

## Install

From GitHub:

    herdr plugin install <owner>/herdr-ocworktrees

Or from a checkout:

    git clone https://github.com/<owner>/herdr-ocworktrees
    cd herdr-ocworktrees
    go build -o herdr-ocworktrees .
    herdr plugin link "$PWD"

Optional keybinding for a manual sync, in herdr's `config.toml`:

    [[keys.command]]
    key = "prefix+o"
    type = "plugin_action"
    command = "anderson.ocworktrees.sync"
    description = "sync OpenCode worktrees"

Then `herdr server reload-config`.

## Configuration

The plugin reads `config.toml` from its config directory
(`herdr plugin config-dir anderson.ocworktrees` prints the path):

    roots = ["~/.local/share/opencode/worktree"]

Defaults to the line above when the file is missing. Each root is scanned up
to three levels deep; directories containing a `.git` file are treated as
linked worktrees.

## Multiple machines

Install the plugin on every machine that runs herdr and OpenCode worktrees.
Each herdr server mirrors its own local worktrees; a client with several
saved machines shows all of them in one sidebar.
