{
  lib,
  stdenv,
  fetchurl,
  glibc,
  patchelf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "plannotator";
  version = "0.28.60";

  src = fetchurl {
    url = "https://github.com/backnotprop/plannotator/releases/download/v${finalAttrs.version}/plannotator-linux-x64";
    hash = "sha256-He0h4JpRUW+G4BhoeuJSeDnzduz+brYAJHlZDJfR4AM=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  nativeBuildInputs = [ patchelf ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/plannotator
    patchelf --set-interpreter ${glibc}/lib64/ld-linux-x86-64.so.2 $out/bin/plannotator
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
