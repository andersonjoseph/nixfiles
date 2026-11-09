{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "plannotator";
  version = "0.28.55";

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${finalAttrs.version}/plannotator-linux-x64";
    hash = "sha256-r8+ESYBDi+U6J9Prs6VMzmdboKYhFXase8VGvfe9XH8=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/plannotator
    runHook postInstall
  '';

  meta = {
    description = "Plan and code review surfaces for coding agents";
    homepage = "https://github.com/backnotprop/plannotator";
    license = lib.licenses.mit;
    mainProgram = "plannotator";
    platforms = [ "x86_64-linux" ];
  };
})
