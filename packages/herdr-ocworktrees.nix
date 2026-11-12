{
  lib,
  buildGoModule,
}:

buildGoModule (finalAttrs: {
  pname = "herdr-ocworktrees";
  version = "0.1.0";

  src = ../flakes/herdr-ocworktrees;
  vendorHash = null;

  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/herdr-ocworktrees
    mv $out/bin/herdr-ocworktrees $out/share/herdr-ocworktrees/herdr-ocworktrees
    rmdir --ignore-fail-on-non-empty $out/bin
    install -m644 $src/herdr-plugin.toml $out/share/herdr-ocworktrees/herdr-plugin.toml
  '';

  meta = {
    description = "herdr plugin that mirrors OpenCode worktrees into herdr workspaces";
    homepage = "https://github.com/andersonjoseph/herdr-ocworktrees";
    license = lib.licenses.mit;
    mainProgram = "herdr-ocworktrees";
    platforms = [ "x86_64-linux" ];
  };
})
