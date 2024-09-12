{
  description = "qperf-msquic";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
        in
        {
          packages.secnetperf = pkgs.stdenv.mkDerivation {
            name = "secnetperf";
            src = self;
            nativeBuildInputs = with pkgs; [
                cmake
            ];
            buildInputs= with pkgs; [
                numactl
                git
                perl
            ];
            cmakeFlags = [
                "-DQUIC_TLS=openssl3"
                "-DQUIC_BUILD_PERF=ON"
                "-DQUIC_BUILD_SHARED=OFF"
            ];
            buildFlags = [
                "secnetperf"
            ];
            patchPhase = ''
                patchShebangs --build submodules/openssl3/Configure
            '';
            installPhase = ''
                #TODO export msquic
                mkdir $out
                mkdir $out/bin
                cp $TMP/source/build/bin/Release/secnetperf $out/bin
            '';
          };
          packages.default = self.packages.${system}.secnetperf;
        }
      );
}