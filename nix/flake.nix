{
  description = "Home Maneger setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      darwin,
      self,
      ...
    }:
    let
      system = "aarch64-darwin";
      user = "mmilani";
    in
    {
      darwinConfigurations."${user}-darwin" = darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.users.${user} = ./home.nix;
            home-manager.extraSpecialArgs = { inherit user; };
          }
        ];
        specialArgs = { inherit inputs system user; };
      };
    };
}
