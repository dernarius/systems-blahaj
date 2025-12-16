{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
  };

  outputs = { self, nixpkgs }@inputs: {

    nixosConfigurations.blahaj = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      # Pass flake inputs to modules (so you can use inputs.nixpkgs in other files)
      specialArgs = { inherit inputs; };
      
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };

  };
}
