{ inputs, lib, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstream = inputs.omarchy-upstream;
  hyprConfigDir = "${upstream}/config/hypr";
  hyprDefaultDir = "${upstream}/default/hypr";
  blocked = "nixarchy-phase2-blocked";

  replaceMany = replacements: text:
    lib.foldl'
      (current: replacement:
        builtins.replaceStrings [ replacement.from ] [ replacement.to ] current)
      text
      replacements;

  patchHyprConfig = text:
    replaceMany [
      {
        from = "~/.local/share/omarchy/default/hypr";
        to = "~/.config/hypr/default";
      }
      {
        from = "~/.local/share/omarchy/default";
        to = "~/.config/omarchy/default";
      }
      {
        from = "uwsm-app -- ";
        to = "";
      }
      {
        from = "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1";
        to = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      }
      {
        from = "! omarchy-toggle-enabled waybar-off && ";
        to = "";
      }
      {
        from = "xdg-terminal-exec --dir=\"$(omarchy-cmd-terminal-cwd)\"";
        to = "alacritty";
      }
      {
        from = "nautilus --new-window \"$(omarchy-cmd-terminal-cwd)\"";
        to = "nautilus --new-window";
      }
      {
        from = "omarchy-launch-walker -m symbols";
        to = "walker --modules symbols";
      }
      {
        from = "omarchy-launch-walker -m clipboard";
        to = "walker --modules clipboard";
      }
      {
        from = "omarchy-launch-walker";
        to = "walker";
      }
      {
        from = "omarchy-system-lock";
        to = "hyprlock";
      }
      {
        from = "omarchy-launch-screensaver";
        to = "hyprlock";
      }
      {
        from = "omarchy-launch-browser --private";
        to = "firefox --private-window";
      }
      {
        from = "omarchy-launch-browser";
        to = "firefox";
      }
      {
        from = "omarchy-launch-editor";
        to = "alacritty -e nvim";
      }
      {
        from = "omarchy-swayosd-client";
        to = "swayosd-client";
      }
      {
        from = "omarchy-launch-or-focus ^signal$ \"signal-desktop\"";
        to = "signal-desktop";
      }
      {
        from = "omarchy-launch-or-focus ^signal$ \"uwsm-app -- signal-desktop\"";
        to = "signal-desktop";
      }
      {
        from = "omarchy-";
        to = "${blocked} omarchy-";
      }
    ] text;

  mkDefaultHyprFile = file:
    let relative = builtins.unsafeDiscardStringContext (lib.removePrefix "${hyprDefaultDir}/" (toString file));
    in {
      name = "hypr/default/${relative}";
      value.text = patchHyprConfig (builtins.readFile file);
    };

  mkConfigHyprFile = name: {
    name = "hypr/${name}";
    value.text = patchHyprConfig (builtins.readFile "${hyprConfigDir}/${name}");
  };

  configHyprFiles = [
    "autostart.conf"
    "bindings.conf"
    "hypridle.conf"
    "hyprlock.conf"
    "input.conf"
    "looknfeel.conf"
    "monitors.conf"
  ];
in {
  home.packages = with pkgs; [
    alacritty
    firefox
    hypridle
    hyprlock
    nautilus
    polkit_gnome
    signal-desktop
    walker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    xwayland.enable = true;
    extraConfig = patchHyprConfig (builtins.readFile "${hyprConfigDir}/hyprland.conf");
  };

  services.hypridle.enable = true;

  xdg.configFile =
    builtins.listToAttrs (map mkDefaultHyprFile (lib.filesystem.listFilesRecursive hyprDefaultDir))
    // builtins.listToAttrs (map mkConfigHyprFile configHyprFiles);
}
