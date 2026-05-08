{ inputs, lib, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
  walkerConfigDir = "${upstream}/config/walker";
  walkerDefaultDir = "${upstream}/default/walker";
  blocked = "nixarchy-phase2-blocked";

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
      {
        from = "omarchy-";
        to = "${blocked} omarchy-";
      }
    ] text;

  mkWalkerDefaultFile = file:
    let relative = builtins.unsafeDiscardStringContext (lib.removePrefix "${walkerDefaultDir}/" (toString file));
    in {
      name = "walker/${relative}";
      value.text = patchWalker (builtins.readFile file);
    };
in {
  home.packages = with pkgs; [ walker ];

  xdg.configFile =
    {
      "walker/config.toml".text = patchWalker (builtins.readFile "${walkerConfigDir}/config.toml");
    }
    // builtins.listToAttrs (map mkWalkerDefaultFile (lib.filesystem.listFilesRecursive walkerDefaultDir));
}
