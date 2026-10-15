{
  lib,
  buildNpmPackage,
  sideshow-src,
}:

let
  version = (lib.importJSON (sideshow-src + "/package.json")).version;
in
buildNpmPackage {
  pname = "sideshow";
  inherit version;
  src = sideshow-src;

  npmDepsHash = "sha256-v/FzVBQ7SpLOt5Z4oG0uJ01YxXS+uT52400uC13BLz4=";

  meta = {
    description = "Live visual surface for terminal coding agents";
    homepage = "https://github.com/modem-dev/sideshow";
    license = lib.licenses.mit;
    mainProgram = "sideshow";
  };
}
