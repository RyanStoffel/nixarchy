{ inputs, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
in {
  home.packages = with pkgs; [
    alacritty
    ghostty
  ];

  xdg.configFile = {
    "alacritty/alacritty.toml".text = builtins.readFile "${upstream}/config/alacritty/alacritty.toml";
    "ghostty/config".text = builtins.readFile "${upstream}/config/ghostty/config";
    "xdg-terminals.list".text = builtins.readFile "${upstream}/config/xdg-terminals.list";
  };
}
