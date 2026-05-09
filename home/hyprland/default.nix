{ inputs, lib, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstream = inputs.omarchy-upstream;
  hyprConfigDir = "${upstream}/config/hypr";
  hyprDefaultDir = "${upstream}/default/hypr";
  blocked = "nixarchy-phase2-blocked";
  terminal = lib.getExe pkgs.alacritty;
  chromium = lib.getExe pkgs.chromium;
  chromiumApp = url: "${chromium} --new-window --app=${url}";
  terminalApp = command: "${terminal} -e ${command}";

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
        from = "exec-once = swayosd-server\n";
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
        to = "${chromium} --incognito";
      }
      {
        from = "omarchy-launch-browser";
        to = chromium;
      }
      {
        from = "omarchy-launch-editor";
        to = "${terminal} -e nvim";
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
        from = "bindd = SUPER CTRL, C, Capture menu, exec, omarchy-menu capture";
        to = ''
          bindd = SUPER CTRL, C, Claude Code, exec, ${terminalApp (lib.getExe pkgs.claude-code)}
          bindd = SUPER CTRL, G, Gemini CLI, exec, ${terminalApp (lib.getExe pkgs.gemini-cli)}
        '';
      }
      {
        from = "bindd = SUPER CTRL, O, Toggle menu, exec, omarchy-menu toggle";
        to = "bindd = SUPER CTRL, O, OpenCode, exec, ${terminalApp (lib.getExe pkgs.opencode)}";
      }
      {
        from = "bindd = SUPER CTRL, X, Toggle dictation, exec, voxtype record toggle";
        to = "bindd = SUPER CTRL, X, Codex CLI, exec, ${terminalApp (lib.getExe pkgs.codex)}";
      }
      {
        from = "bindd = SUPER SHIFT, C, Calendar, exec, omarchy-launch-webapp \"https://app.hey.com/calendar/weeks/\"";
        to = ''
          bindd = SUPER SHIFT, C, VS Code, exec, ${lib.getExe pkgs.vscode}
          bindd = SUPER SHIFT, Z, Zed, exec, ${lib.getExe pkgs.zed-editor}
        '';
      }
      {
        from = "bindd = SUPER SHIFT, D, Docker, exec, omarchy-launch-tui lazydocker";
        to = ''
          bindd = SUPER SHIFT, D, Discord, exec, ${lib.getExe pkgs.discord}
          bindd = SUPER SHIFT ALT, D, LazyDocker, exec, ${terminalApp (lib.getExe pkgs.lazydocker)}
        '';
      }
      {
        from = "bindd = SUPER SHIFT, G, Signal, exec, signal-desktop";
        to = "bindd = SUPER SHIFT, G, Steam, exec, ${lib.getExe pkgs.steam}";
      }
      {
        from = "bindd = SUPER SHIFT, M, Music, exec, omarchy-launch-or-focus spotify";
        to = "bindd = SUPER SHIFT, S, Spotify, exec, ${lib.getExe pkgs.spotify}";
      }
      {
        from = "bindd = SUPER SHIFT ALT, M, Music TUI, exec, omarchy-launch-or-focus-tui cliamp";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, SLASH, Passwords, exec, 1password";
        to = "bindd = SUPER SHIFT, SLASH, 1Password, exec, ${lib.getExe pkgs._1password-gui}";
      }
      {
        from = "bindd = SUPER SHIFT, A, ChatGPT, exec, omarchy-launch-webapp \"https://chatgpt.com\"";
        to = ''
          bindd = SUPER SHIFT, A, Claude, exec, ${chromiumApp "https://claude.ai"}
          bindd = SUPER SHIFT ALT, A, ChatGPT, exec, ${chromiumApp "https://chatgpt.com"}
          bindd = SUPER SHIFT CTRL, A, Gemini, exec, ${chromiumApp "https://gemini.google.com"}
          bindd = SUPER SHIFT, T, Microsoft Teams, exec, ${chromiumApp "https://teams.microsoft.com/v2/"}
          bindd = SUPER SHIFT, L, Slack, exec, ${chromiumApp "https://app.slack.com/client"}
        '';
      }
      {
        from = "bindd = SUPER SHIFT ALT, A, Grok, exec, omarchy-launch-webapp \"https://grok.com\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, Y, YouTube, exec, omarchy-launch-webapp \"https://youtube.com/\"";
        to = "bindd = SUPER SHIFT, Y, YouTube, exec, ${chromiumApp "https://youtube.com"}";
      }
      {
        from = "bindd = SUPER SHIFT, O, Obsidian, exec, omarchy-launch-or-focus ^obsidian$ \"obsidian\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, W, Typora, exec, typora --enable-wayland-ime";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, E, Email, exec, omarchy-launch-webapp \"https://app.hey.com\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT ALT, G, WhatsApp, exec, omarchy-launch-or-focus-webapp WhatsApp \"https://web.whatsapp.com/\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT CTRL, G, Google Messages, exec, omarchy-launch-or-focus-webapp \"Google Messages\" \"https://messages.google.com/web/conversations\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, P, Google Photos, exec, omarchy-launch-or-focus-webapp \"Google Photos\" \"https://photos.google.com/\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT, X, X, exec, omarchy-launch-webapp \"https://x.com/\"";
        to = "";
      }
      {
        from = "bindd = SUPER SHIFT ALT, X, X Post, exec, omarchy-launch-webapp \"https://x.com/compose/post\"";
        to = "";
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
