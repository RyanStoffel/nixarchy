{
  description = "Nixarchy - Omarchy on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      mkSystem = {
        system ? "x86_64-linux",
        hostname ? "nixarchy",
        username ? "nixarchy",
      }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs hostname username; };
        modules = [ ./hosts/nixarchy.nix ];
      };
    in {
      nixosModules.default = ./modules;
      homeManagerModules.default = ./home;

      nixosConfigurations.nixarchy = mkSystem { };
    };
}
