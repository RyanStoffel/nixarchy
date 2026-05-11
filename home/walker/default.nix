{ inputs, lib, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
  walkerConfigDir = "${upstream}/config/walker";
  walkerDefaultDir = "${upstream}/default/walker";

  replaceMany = replacements: text:
    lib.foldl'
      (current: replacement:
        builtins.replaceStrings [ replacement.from ] [ replacement.to ] current)
      text
      replacements;

  patchWalker = text:
    replaceMany [
      {
        from = "~/.local/share/omarchy/default/walker/themes/";
        to = "~/.config/walker/themes/";
      }
      {
        from = ''@import "../../../../../../../.config/omarchy/current/theme/walker.css";'';
        to = ''@import "../../../omarchy/current/theme/walker.css";'';
      }
    ] text;

  mkWalkerDefaultFile = file:
    let relative = builtins.unsafeDiscardStringContext (lib.removePrefix "${walkerDefaultDir}/" (toString file));
    in {
      name = "walker/${relative}";
      value.text = patchWalker (builtins.readFile file);
    };
in {
  home.packages = with pkgs; [ walker elephant ];

  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant data provider (Walker backend)";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.walker = {
    Unit = {
      Description = "Walker launcher (gapplication service for super+space prewarm)";
      After = [ "hyprland-session.target" "elephant.service" ];
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Environment = "GSK_RENDERER=cairo";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };

  xdg.configFile =
    {
      "walker/config.toml".text = patchWalker (builtins.readFile "${walkerConfigDir}/config.toml");
    }
    // builtins.listToAttrs (map mkWalkerDefaultFile (lib.filesystem.listFilesRecursive walkerDefaultDir));
}
