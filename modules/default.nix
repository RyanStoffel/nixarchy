{ ... }: {
  imports = [
    ./desktop/audio.nix
    ./desktop/hyprland.nix
    ./desktop/sddm.nix
    ./system/boot.nix
    ./system/fonts.nix
    ./system/locale.nix
    ./system/networking.nix
    ./system/packages.nix
  ];
}
