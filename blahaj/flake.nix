{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            openblas = prev.openblas.overrideAttrs (old: {
              doCheck = false; # Disables the failing tests
            });
          })
        ];
      };
    in
    {

      nixosConfigurations.blahaj = nixpkgs.lib.nixosSystem {
        inherit system;

        # Pass flake inputs to modules (so you can use inputs.nixpkgs in other files)
        specialArgs = { inherit pkgs-unstable; };

        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          ./gaming.nix
          ./tv-shenanigans.nix
        ];
      };

    };
}
