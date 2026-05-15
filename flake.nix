{
  description = "qperf-msquic";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          packages.default = pkgs.stdenv.mkDerivation {
            name = "msquic";
            src = self;
            strictDeps = true;
            nativeBuildInputs =
              with pkgs;
              [
                cmake
                perl
              ]
              ++ lib.optionals stdenv.hostPlatform.isLinux [
                autoPatchelfHook
              ];
            buildInputs =
              with pkgs;
              [ libatomic_ops ]
              ++ lib.optionals stdenv.hostPlatform.isLinux [
                stdenv.cc.cc.lib
                lttng-tools
              ];
            cmakeFlags = [
              "-DQUIC_BUILD_TOOLS=ON"
              "-DQUIC_BUILD_PERF=ON"
            ];
            # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/li/libmsquic/package.nix#L49
            postUnpack = with pkgs; ''
              for f in "$(find . -type f -name "*.pl")"; do
                patchShebangs --build $f 2>&1 > /dev/null
              done
              for g in $(find . -type f -name "*"); do
                if test -f $g; then
                  sed -i "s|/usr/bin/env|${coreutils}/bin/env|g" $g
                fi
              done
            '';
            installPhase = ''
              runHook preInstall
              cmake --install . --prefix $out
              mkdir -p $out/bin
              find bin -mindepth 2 -maxdepth 2 -type f ! -name "*.so*" -exec cp {} $out/bin/ \;
              runHook postInstall
            '';
            preFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
              for f in $out/bin/*; do
                if [ -f "$f" ] && [ -x "$f" ]; then
                  patchelf --set-rpath "$out/lib" "$f"
                fi
              done
              autoPatchelfLibs+=($out/lib)
            '';
          };
        };
    };
}
