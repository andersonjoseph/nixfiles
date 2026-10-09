{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libx11,
  libxcomposite,
  libxcb,
  libxcursor,
  libxdamage,
  libxfixes,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
}:
let
  version = "0.13.4";
in
stdenv.mkDerivation {
  pname = "terminal-browser";
  inherit version;

  src = fetchurl {
    url = "https://github.com/zenbu-labs/terminal-browser/releases/download/v${version}/terminal-browser-linux-x64.tar.gz";
    sha256 = "6277daaabab16711ab3f1961cdffad9efac5e70ac55d5076e2c86496d649d3a4";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libx11
    libxcomposite
    libxcb
    libxcursor
    libxdamage
    libxfixes
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
    mesa
    nspr
    nss
    pango
    systemd
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  # bin/terminal-browser resolves its own symlinks and finds the bundled
  # electron next to itself, so a plain symlink into $out/bin is enough.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/opt/terminal-browser $out/bin
    cp -r . $out/opt/terminal-browser/
    ln -s ../opt/terminal-browser/bin/terminal-browser $out/bin/terminal-browser
    runHook postInstall
  '';

  meta = {
    description = "A browser inside your terminal, driven by coding agents";
    homepage = "https://github.com/zenbu-labs/terminal-browser";
    license = lib.licenses.mit;
    mainProgram = "terminal-browser";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
