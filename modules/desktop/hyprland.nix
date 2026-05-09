{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services.udev.packages = with pkgs; [
    brightnessctl
    swayosd
  ];

  security.polkit.enable = true;
}
