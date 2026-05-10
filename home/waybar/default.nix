{ inputs, lib, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
  waybarDir = "${upstream}/config/waybar";

  replaceMany = replacements: text:
    lib.foldl'
      (current: replacement:
        builtins.replaceStrings [ replacement.from ] [ replacement.to ] current)
      text
      replacements;

  patchConfig = text:
    replaceMany [
      {
        from = ''  "modules-left": ["custom/omarchy", "hyprland/workspaces"],'';
        to = ''  // TODO Phase 4: restore custom/omarchy after omarchy-menu is packaged.
  "modules-left": ["hyprland/workspaces"],'';
      }
      {
        from = ''  "modules-center": ["clock", "custom/update", "custom/voxtype", "custom/screenrecording-indicator", "custom/idle-indicator", "custom/notification-silencing-indicator"],'';
        to = ''  // TODO Phase 4: restore custom update, recorder, idle, notification, and voxtype modules.
  "modules-center": ["clock"],'';
      }
      {
        from = "omarchy-launch-or-focus-tui btop";
        to = "alacritty -e btop";
      }
      {
        from = "xdg-terminal-exec";
        to = "alacritty";
      }
      {
        from = "$OMARCHY_PATH";
        to = "${upstream}";
      }
    ] text;
in {
  home.packages = with pkgs; [ waybar ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile = {
    "waybar/config.jsonc".text = patchConfig (builtins.readFile "${waybarDir}/config.jsonc");
    "waybar/style.css".text = builtins.readFile "${waybarDir}/style.css";
  };
}
