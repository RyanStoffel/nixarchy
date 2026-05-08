{ username ? "nixarchy", ... }: {
  imports = [
    ./hyprland
    ./omarchy-theme
    ./phase2-blocked.nix
    ./shell.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
