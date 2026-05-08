{ inputs, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
in {
  home.packages = with pkgs; [ alacritty ];

  xdg.configFile = {
    "alacritty/alacritty.toml".text = builtins.readFile "${upstream}/config/alacritty/alacritty.toml";
    "xdg-terminals.list".text = builtins.readFile "${upstream}/config/xdg-terminals.list";
  };
}
