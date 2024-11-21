# {
#   description = "A Nix-flake-based C/C++ development environment";
#
#   inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
#
#   outputs = { self, nixpkgs }:
#     let
#       supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
#       forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
#         pkgs = import nixpkgs { inherit system; };
#       });
#     in
#     {
#       devShells = forEachSupportedSystem ({ pkgs }: {
#         default = pkgs.mkShell.override {
#           # Override stdenv in order to change compiler:
#           # stdenv = pkgs.clangStdenv;
#         }
#         {
#           packages = with pkgs; [
#             clang-tools
#             cmake
#             codespell
#             conan
#             cppcheck
#             doxygen
#             gtest
#             lcov
#             vcpkg
#             vcpkg-tool
#           ] ++ (if system == "aarch64-darwin" then [ ] else [ gdb ]);
#         };
#       });
#     };
# }


{
  description = "A Nix-flake-based Rust development environment";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default self.overlays.default ];
        };
      });
    in
    {
      overlays.default = final: prev: {
        rustToolchain =
          let
            rust = prev.rust-bin;
          in
          if builtins.pathExists ./rust-toolchain.toml then
            rust.fromRustupToolchainFile ./rust-toolchain.toml
          else if builtins.pathExists ./rust-toolchain then
            rust.fromRustupToolchainFile ./rust-toolchain
          else
            rust.stable.latest.default.override {
              extensions = [ "rust-src" "rustfmt" ];
            };
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            rustToolchain
            openssl
            pkg-config
            cargo-deny
            cargo-edit
            cargo-watch
            rust-analyzer
            wasm-pack
            # C/C++ Libraries
            clang-tools
            cmake
            codespell
            conan
            cppcheck
            doxygen
            gtest
            lcov
            vcpkg
            vcpkg-tool
          ];

          env = {
            # Required by rust-analyzer
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      });
    };
}

