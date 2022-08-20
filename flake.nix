{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";

    blackmagic_src.url = "git+https://github.com/blackmagic-debug/blackmagic?submodules=1";
    blackmagic_src.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, blackmagic_src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          default = blackmagic;

          blackmagic = pkgs.stdenv.mkDerivation rec {
            pname = "blackmagic";
            version = "0.0.0";

            src = blackmagic_src;

            postPatch = ''
              patchShebangs .
              cat > ./src/include/version.h <<EOF
              #define FIRMWARE_VERSION "v1.8.0-${blackmagic_src.shortRev}"
              EOF
            '';

            buildPhase = ''
              make PROBE_HOST=stlink ST_BOOTLOADER=1
            '';

            installPhase = ''
              mkdir -p $out/share/blackmagic/
              install -T src/blackmagic.bin $out/share/blackmagic/blackmagic-stlink-bootloader.bin
            '';

            nativeBuildInputs = [
              pkgs.gcc-arm-embedded
              pkgs.python3Packages.python
            ];
          };
        };
      }
    );
}
