# T3 Code desktop app launchers, ported from ~/projects/t3-jailed/flake.nix.
#
# `t3-jailed` runs the app with jailed-agents wrappers for claude/pi on PATH so
# every provider T3 spawns runs in a bubblewrap sandbox; `t3` is the un-jailed
# variant with the same pinned agent CLIs prepended to PATH.
#
# Upgrading T3 Code: bump t3Version plus the t3AppImage and t3-cli hashes
# (both URLs are derived from the version):
#   nix store prefetch-file <release-asset-url> --hash-type sha256
#   nix store prefetch-file <npm-tarball-url> --hash-type sha256
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

  # `t3` CLI from the npm distribution: a prebuilt native binary (no node
  # at runtime) with the web client assets next to it, so install the whole
  # package dir and link only the binary into bin.
  t3-cli = pkgs.stdenv.mkDerivation {
    pname = "t3-cli";
    version = t3Version;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@t3code/t3-linux-x64/-/t3-linux-x64-${t3Version}.tgz";
      hash = "sha256-IcRU3DOoOiwOnrpak3L7W4Ao2VhGM5Wi1RVpwTEfCXE=";
    };
    sourceRoot = "package";
    # The blob links against a plain-FHS interpreter (/lib64/ld-linux) that
    # bare NixOS lacks — the unpatched binary dies with exec ENOENT (shell
    # exit 127) outside an appimage-run env. autoPatchelf rewires it and the
    # bundled node_modules natives onto nixpkgs' glibc/gcc runtimes
    # (libstdc++/libatomic come from gcc's lib output).
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [
      pkgs.stdenv.cc.libc
      pkgs.libgcc
      pkgs.stdenv.cc.cc.lib
    ];
    dontConfigure = true;
    dontBuild = true;
    # Keep the 166 MB blob byte-intact apart from the interpreter/rpath fix.
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/t3-cli $out/bin
      cp -r . $out/libexec/t3-cli/
      chmod +x $out/libexec/t3-cli/t3
      ln -s $out/libexec/t3-cli/t3 $out/bin/t3
      runHook postInstall
    '';
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
  # NOTE: keep these shims ahead of t3-plain-agents-bin on PATH, else T3
  # resolves the un-jailed CLIs and the jails never run.
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

  # t3-jailed must not exec t3: t3 prepends the un-jailed bin, which would
  # shadow the jailed shims (that bug let T3 spawn agents un-jailed).
  launchApp = "${pkgs.appimage-run}/bin/appimage-run ${t3AppImage} \"$@\"";

  t3 = pkgs.writeShellScriptBin "t3" ''
    export PATH="${unjailedBin}/bin:$PATH"
    export LANG="''${LANG:-C.UTF-8}"
    export TERM="''${TERM:-xterm-256color}"
    exec ${launchApp}
  '';

  t3-jailed = pkgs.writeShellScriptBin "t3-jailed" ''
    export PATH="${agentsBin}/bin:$PATH"
    export LANG="''${LANG:-C.UTF-8}"
    export TERM="''${TERM:-xterm-256color}"
    exec ${launchApp}
  '';

  # T3 downloads its preview browser (chrome-headless-shell) at runtime into
  # ~/.t3/tools — a plain-FHS prebuilt that bare NixOS cannot exec (no
  # /lib64 loader, no nss/x11 libs) and whose version-stamped path makes
  # per-download patchelf a treadmill. Run the server inside an FHS env so
  # runtime downloads just work — the same /lib64 the desktop AppImage gets
  # from appimage-run, made explicit. The autoPatchelf'd t3 binary keeps its
  # store interpreter (FHS binds /nix read-only), and the jailed provider
  # shims on PATH still exec their own bwrap from inside it.
  t3-fhs = pkgs.buildFHSEnv {
    name = "t3-fhs";
    targetPkgs =
      p: with p; [
        # chrome-headless-shell runtime
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        liberation_ttf
        libdrm
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libXrender
        libxcb
        libxkbcommon
        mesa
        nspr
        nss
        pango
        stdenv.cc.cc.lib
      ];
    runScript = "${t3-cli}/bin/t3";
  };

  # Headless server launcher for the vondel service: jailed provider shims,
  # git, and the system profile on PATH — systemd user services start with
  # a minimal PATH.
  t3-serve = pkgs.writeShellScriptBin "t3-serve" ''
    export PATH="${agentsBin}/bin:${pkgs.git}/bin:/run/current-system/sw/bin:$PATH"
    export LANG="''${LANG:-C.UTF-8}"
    export TERM="''${TERM:-xterm-256color}"
    exec ${t3-fhs}/bin/t3-fhs serve "$@"
  '';
in
{
  inherit
    t3
    t3-jailed
    t3-cli
    t3-serve
    ;
}
