{
  appimageTools,
  fetchurl,
  makeDesktopItem,
}:
let
  version = "0.1.3";
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha512-VXzewcCuHr9gp7WqORwBugsbfiPglnUP5knifdJiMxIcKrDu3ZLTPqNG5oUp5d9BwtSM5vmN+sPyXXPy5jYLdg==";
  };
  appimageContents = appimageTools.extract {
    pname = "t3code";
    inherit version src;
  };
  desktopItem = makeDesktopItem {
    name = "t3code";
    desktopName = "T3 Code";
    exec = "t3code-desktop %U";
    icon = "t3code";
    comment = "Open-source desktop app for coding agents";
    terminal = false;
    categories = [ "Development" ];
    startupWMClass = "t3code";
    mimeTypes = [
      "x-scheme-handler/t3code"
      "x-scheme-handler/t3code-dev"
    ];
  };
in
appimageTools.wrapAppImage {
  pname = "t3code-appimage";
  inherit version;
  src = appimageContents;
  extraInstallCommands = ''
    install -Dm644 ${appimageContents}/t3code.png $out/share/icons/hicolor/512x512/apps/t3code.png
    cp -r ${desktopItem}/share/applications $out/share/
    ln -s t3code-appimage $out/bin/t3code-desktop
  '';
}
