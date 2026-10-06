{
  lib,
  buildNpmPackage,
}:
buildNpmPackage {
  pname = "walkthrough";
  version = "0.1.0";
  src = ./walkthrough;
  npmDepsHash = "sha256-nGYiRwyhrzTtlGnpwiuWS5icmn/5iW6fqp7Q0LXzFZs=";

  buildPhase = ''
    runHook preBuild
    npm run build
    patchShebangs bin/wt.cjs
    chmod +x bin/wt.cjs
    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck
    npm run test
    runHook postCheck
  '';

  doCheck = true;

  meta = {
    description = "Deterministic commit walkthrough pages from git plus a curated sidecar";
    license = lib.licenses.mit;
    mainProgram = "wt";
  };
}
