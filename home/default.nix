{ username ? "nixarchy", ... }: {
  imports = [
    ./auxiliary
    ./hyprland
    ./mako
    ./omarchy-theme
    ./shell.nix
    ./terminals
    ./walker
    ./waybar
    ./webapps
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
