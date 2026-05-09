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
        from = "exec-once = ! omarchy-toggle-enabled waybar-off && waybar\n";
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
        to = "${pkgs.swayosd}/bin/swayosd-client";
      }
      {
        from = "omarchy-audio-input-mute";
        to = "${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle";
      }
      {
        from = "omarchy-brightness-display +5%";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness +5";
      }
      {
        from = "omarchy-brightness-display 5%-";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness -5";
      }
      {
        from = "omarchy-brightness-display 100%";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness 100";
      }
      {
        from = "omarchy-brightness-display 1%-";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness -1";
      }
      {
        from = "omarchy-brightness-display +1%";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness +1";
      }
      {
        from = "omarchy-brightness-display 1%";
        to = "${pkgs.swayosd}/bin/swayosd-client --brightness 1";
      }
      {
        from = "omarchy-brightness-keyboard up";
        to = "${pkgs.brightnessctl}/bin/brightnessctl --class=leds --device='*::kbd_backlight' set +1";
      }
      {
        from = "omarchy-brightness-keyboard down";
        to = "${pkgs.brightnessctl}/bin/brightnessctl --class=leds --device='*::kbd_backlight' set 1-";
      }
      {
        from = "omarchy-brightness-keyboard cycle";
        to = "${pkgs.brightnessctl}/bin/brightnessctl --class=leds --device='*::kbd_backlight' set +1";
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
        from = "    col.border_locked_active = -1\n    col.border_locked_inactive = -1";
        to = "    col.border_locked_active = $activeBorderColor\n    col.border_locked_inactive = $inactiveBorderColor";
      }
      {
        from = "    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below\n";
        to = "";
      }
      {
        from = "\n# Toggle config flags dynamically\nsource = ~/.local/state/omarchy/toggles/hypr/*.conf\n";
        to = "\n# Toggle config flags dynamically (omitted on NixOS because empty globs error)\n";
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
