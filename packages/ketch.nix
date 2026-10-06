{
  lib,
  buildGoModule,
  ketch-src,
}:

let
  version = "0.18.1";
in
buildGoModule {
  pname = "ketch";
  inherit version;
  src = ketch-src;

  vendorHash = "sha256-NqZlxCbXfH4OJQGEVQwA6uu5LLlKDmwGYDRM6V8U/+4=";

  # Golden fixture asserts user_agent "ketch/dev"; fails with the stamped version.
  checkFlags = [ "-skip=^TestRegistryConfigCompatibilityGolden$" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/1broseidon/ketch/cmd.version=${version}"
  ];

  meta = {
    description = "Stateless CLI for web search, code search, library docs, and scraping";
    homepage = "https://github.com/1broseidon/ketch";
    license = lib.licenses.mit;
    mainProgram = "ketch";
  };
}
