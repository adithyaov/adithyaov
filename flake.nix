{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      hp = pkgs.haskellPackages;

      # build-only: keep devTools empty so it returns a derivation
      buildPkg = hp.developPackage {
        root = ./.;
        returnShellEnv = false;
      };

      # dev shell: request a shell environment (and add editor tools)
      shellPkg = hp.developPackage {
        root = ./.;
        returnShellEnv = true; # <-- forces a shell-like attribute set
      };
    in
    {
      packages.${system}.default = buildPkg; # this is a drv (nix build ...)
      devShells.${system}.default = shellPkg; # nix develop -> shell
    };
}
