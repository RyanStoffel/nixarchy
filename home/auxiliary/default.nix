{ inputs, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
in {
  home.packages = with pkgs; [ btop ];

  xdg.configFile = {
    "btop/btop.conf".text = builtins.readFile "${upstream}/config/btop/btop.conf";
    "btop/themes/current.theme".text = builtins.readFile "${upstream}/themes/tokyo-night/btop.theme";
  };
}
