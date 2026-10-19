{
  description = "Redlib: Private front-end for Reddit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        redlib = pkgs.rustPlatform.buildRustPackage {
          pname = "redlib";
          version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
          src = pkgs.lib.cleanSource ./.;
          cargoLock.lockFile = ./Cargo.lock;
          doCheck = false;

          # boring-sys2 (via wreq) patches and builds BoringSSL from source
          nativeBuildInputs = with pkgs; [ git cmake rustPlatform.bindgenHook ];
        };
      in
      {
        checks.default = redlib;

        packages.default = redlib;
        packages.docker = pkgs.dockerTools.buildLayeredImage {
          name = "quay.io/redlib/redlib";
          tag = "latest";
          created = "now";
          contents = with pkgs.dockerTools; [ caCertificates fakeNss ];
          config.Cmd = [ "${redlib}/bin/redlib" ];
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ redlib ];
        };
      });
}
