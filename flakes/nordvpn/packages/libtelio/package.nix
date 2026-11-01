{
  clang,
  cmake,
  fetchFromGitHub,
  git,
  lib,
  libpcap,
  pkg-config,
  protobuf,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "libtelio";
  version = "6.2.3";

  src = fetchFromGitHub {
    owner = "NordSecurity";
    repo = "libtelio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5AjRfMHzxP9xX7yMYEpaZXFIFeXzcU5W2JAvZUNsia4=";
  };

  nativeBuildInputs = [
    clang # aws-lc-sys bindgen (libclang)
    cmake # aws-lc-sys
    git # needed by dependency neptun
    pkg-config
    protobuf
  ];

  buildInputs = [
    libpcap # needed by dependency neptun
  ];

  cargoHash = "sha256-e5JSEy6z/YUE+7b7HT+SNn6BZ8uDNf8riwfaZ59DSxU=";

  # test_runner.sh wraps every call in sudo, which the build sandbox lacks.
  patches = [
    ./libtelio.patch
  ];

  postPatch = ''
    patchShebangs test_runner.sh
    # llt-proto (a vendored git dependency) references ../../ens/ens.proto
    # relative to its crate dir inside $cargoDepsCopy, so it resolves to
    # $cargoDepsCopy/ens. Re-inject the proto dropped by cargo vendoring.
    mkdir -p "$cargoDepsCopy/ens"
    cp ${./ens.proto} "$cargoDepsCopy/ens/ens.proto"
  '';

  env = {
    # the llt suite expects proprietary NordVPN secrets we do not have
    BYPASS_LLT_SECRETS = "1";
    LIBCLANG_PATH = "${clang.cc.lib}/lib";
  };

  # same reason: the tests need those secrets and a live network
  doCheck = false;

  meta = {
    description = "A library providing networking utilities for NordVPN.";
    homepage = "https://github.com/NordSecurity/libtelio";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ sanferdsouza ];
    platforms = lib.platforms.linux;
  };
})
