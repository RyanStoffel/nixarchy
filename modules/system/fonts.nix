{ inputs, pkgs, ... }:
let
  omarchy-font = pkgs.callPackage ../../pkgs/omarchy-font {
    src = inputs.omarchy-upstream;
  };
in {
  fonts.packages = with pkgs; [
    omarchy-font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    font-awesome
  ];
}
