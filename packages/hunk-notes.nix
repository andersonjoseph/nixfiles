{
  lib,
  writeShellScriptBin,
  hunk,
  jq,
  git,
}:
writeShellScriptBin "hunk-notes" (
  ''
    PATH=${lib.makeBinPath [ hunk jq git ]}:$PATH
  ''
  + builtins.readFile ./hunk-notes.sh
)
