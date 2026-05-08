{ username ? "nixarchy", ... }: {
  imports = [
    ./hyprland
    ./mako
    ./omarchy-theme
    ./phase2-blocked.nix
    ./shell.nix
    ./walker
    ./waybar
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
