{ inputs, lib, hostname ? "nixarchy", username ? "nixarchy", ... }: {
  imports = [
    ./hardware-configuration.nix
    inputs.self.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = hostname;

  # Evaluation fallback only. Replace hosts/hardware-configuration.nix before install.
  fileSystems."/" = lib.mkDefault {
    device = "none";
    fsType = "tmpfs";
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "input" "networkmanager" ];
    initialPassword = username;
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = import ../home;
  home-manager.extraSpecialArgs = { inherit inputs hostname username; };

  system.stateVersion = "24.11";
}
