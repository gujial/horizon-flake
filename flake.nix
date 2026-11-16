{
  description = "Horizon launcher upstream release for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.horizon-release = {
    url = "file+https://api.github.com/repos/horizon-rust/horizon/releases?per_page=100";
    flake = false;
  };

  outputs =
    { nixpkgs, horizon-release, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      release = import ./release.nix {
        inherit (nixpkgs) lib;
        releases = builtins.fromJSON (builtins.readFile horizon-release);
      };
      horizon = pkgs.callPackage ./package.nix { inherit release; };
    in
    {
      packages.${system} = {
        default = horizon;
        horizon-launcher = horizon;
      };
      apps.${system}.default = {
        type = "app";
        program = "${horizon}/bin/horizon-launcher";
        meta.description = "Launch Horizon";
      };
      checks.${system}.package = horizon;
      formatter.${system} = pkgs.nixfmt;
      overlays.default = final: prev: {
        horizon-launcher = final.callPackage ./package.nix { inherit release; };
      };
    };
}
