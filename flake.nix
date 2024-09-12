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
          packages.msquic = pkgs.stdenv.mkDerivation {
            name = "secnetperf";
            src = self;
            buildInputs= with pkgs; [
                cmake
                numactl
                git
                perl
            ];
            buildPhase = ''
                patchShebangs --build $TMP/source/submodules/openssl3/Configure
                cmake -DCMAKE_BUILD_TYPE=Release -DQUIC_TLS=openssl3 -DQUIC_BUILD_PERF=ON -DQUIC_BUILD_SHARED=OFF -S $TMP/source -B $TMP/source/build
                cmake --build $TMP/source/build --target secnetperf -- -j 10
                mkdir $out
                mkdir $out/bin
                mv $TMP/source/build/bin/Release/secnetperf $out/bin/
            '';
          };
          packages.default = self.packages.${system}.msquic;
        }
      );
}