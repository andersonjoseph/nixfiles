# T3 Code desktop app launchers, ported from ~/projects/t3-jailed/flake.nix.
#
# `t3-jailed` runs the app with jailed-agents wrappers for claude/pi on PATH so
# every provider T3 spawns runs in a bubblewrap sandbox; `t3` is the un-jailed
# variant with the same pinned agent CLIs prepended to PATH.
#
# Upgrading T3 Code: bump t3Version and the t3AppImage hash (release-asset URL
# is derived from the version):
#   nix store prefetch-file <release-asset-url> --hash-type sha256
{
  pkgs,
  agentsLib,
  llmAgentsPackages,
}:

let
  t3Version = "0.1.0";
  t3AppImage = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${t3Version}/T3-Code-${t3Version}-x86_64.AppImage";
    hash = "sha256-442cX7UTsezgpwi5BtM4O1tH7RmVdbOaMeQauINOt0Q=";
  };

  # Env vars T3 sets on its provider spawns; forwarded into the jails.
  t3FwdEnv = [
    "T3_MCP_URL"
    "T3_MCP_BEARER_TOKEN"
    "T3_PI_MCP_EXTENSION_PATH"
    "T3_PI_RUNTIME_MODE"
    "T3_CODE_ORCHESTRATION_INSTRUCTIONS"
  ];

  commonAgentOptions = {
    enableOpenUrls = true;
    enableGitWorktrees = {
      enable = true;
      mountGitConfig = true;
    };
    extraReadonlyDirs = [ "~/.t3/caches" ];
  };

  t3Claude = agentsLib.makeJailedClaudeCode (
    commonAgentOptions
    // {
      name = "claude";
      fwdEnv = t3FwdEnv ++ [
        "ANTHROPIC_API_KEY"
        "ANTHROPIC_AUTH_TOKEN"
        "ANTHROPIC_BASE_URL"
      ];
    }
  );

  t3Pi = agentsLib.makeJailedPi (
    commonAgentOptions
    // {
      name = "pi";
      fwdEnv = t3FwdEnv ++ [
        "OPENAI_API_KEY"
        "ANTHROPIC_API_KEY"
        "OPENROUTER_API_KEY"
      ];
    }
  );

  # T3 spawns provider CLIs with a controlled environment; the jail wrappers
  # abort on unset LANG/TERM, so default them before exec'ing.
  makeAgentShim =
    name: pkg:
    pkgs.writeShellScriptBin name ''
      export LANG="''${LANG:-C.UTF-8}"
      export TERM="''${TERM:-xterm-256color}"
      exec ${pkg}/bin/${name} "$@"
    '';

  agentsBin = pkgs.buildEnv {
    name = "t3-jailed-agents-bin";
    paths = [
      (makeAgentShim "claude" t3Claude)
      (makeAgentShim "pi" t3Pi)
    ];
    pathsToLink = [ "/bin" ];
  };

  # Same agent versions the jails wrap, un-jailed.
  unjailedBin = pkgs.buildEnv {
    name = "t3-plain-agents-bin";
    paths = [
      llmAgentsPackages.claude-code
      llmAgentsPackages.pi
    ];
    pathsToLink = [ "/bin" ];
  };

  t3 = pkgs.writeShellScriptBin "t3" ''
    export PATH="${unjailedBin}/bin:$PATH"
    exec ${pkgs.appimage-run}/bin/appimage-run ${t3AppImage} "$@"
  '';

  t3-jailed = pkgs.writeShellScriptBin "t3-jailed" ''
    export PATH="${agentsBin}/bin:$PATH"
    export LANG="''${LANG:-C.UTF-8}"
    export TERM="''${TERM:-xterm-256color}"
    exec ${t3}/bin/t3 "$@"
  '';
in
{
  inherit t3 t3-jailed;
}
