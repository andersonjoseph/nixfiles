{
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
  version = "6.1.0";

  src = fetchFromGitHub {
    owner = "NordSecurity";
    repo = "libtelio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DzRRacu2LmNqoROrcrrxG9yAEaiaNPWb5QvEbzTlOts=";
  };

  nativeBuildInputs = [
    git # needed by dependency neptun
    pkg-config
    protobuf
  ];

  buildInputs = [
    libpcap # needed by dependency neptun
  ];

  cargoHash = "sha256-EIyToZN4YyZ7pqVBtLuKhvg5wC+xWmcAku5bsaOGEFY=";

  patches = [
    ./libtelio.patch
  ];

  postPatch = ''
    patchShebangs test_runner.sh
  '';

  env = {
    BYPASS_LLT_SECRETS = "1";
  };

  doCheck = false;

  meta = {
    description = "A library providing networking utilities for NordVPN.";
    homepage = "https://github.com/NordSecurity/libtelio";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ sanferdsouza ];
    platforms = lib.platforms.linux;
  };
})
