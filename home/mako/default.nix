{ inputs, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;

  patchMako = text:
    builtins.replaceStrings
      [ "~/.local/share/omarchy/default" ]
      [ "~/.config/omarchy/default" ]
      text;
in {
  home.packages = with pkgs; [ mako ];

  services.mako.enable = true;

  xdg.configFile = {
    "mako/config".text = patchMako (builtins.readFile "${upstream}/default/themed/mako.ini.tpl");
    "omarchy/default/mako/core.ini".text = patchMako (builtins.readFile "${upstream}/default/mako/core.ini");
  };
}
