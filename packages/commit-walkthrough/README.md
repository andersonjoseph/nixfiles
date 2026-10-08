# commit-walkthrough

`wt` renders one HTML page that walks a reader through a commit range.
The page is build output. Git gives titles, dates, stats, message bodies,
and diff rows. A sidecar JSON holds the curated parts: why prose,
pseudocode, diagrams, code coordinates, groups, line notes. The same
sidecar plus the same repo renders the same bytes. The page is one file,
works offline, and never gets edited by hand.

## Install

From a clone:

    nix profile install git+file://<clone-path>
    npm install --global git+file://<clone-path>

From a pushed remote:

    nix profile install github:<owner>/commit-walkthrough
    npm install --global github:<owner>/commit-walkthrough

No install at all:

    node bin/wt.cjs render <range>

The command is `wt`. Example:

    wt init main~3..HEAD "phase 3"
    wt render main~3..HEAD

## Use with opencode

The agent skill is vendored in this repo at
`home/opencode/skills/commit-walkthrough` and linked into
`~/.config/opencode/skills` by home-manager. Skill flow, sidecar schema,
curation rules, and diagram forms are documented in the skill file
itself.

## Develop

    npm ci
    npm run build
    npm test
