{ inputs, lib, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;
  colors = builtins.fromTOML (builtins.readFile "${upstream}/themes/tokyo-night/colors.toml");

  phase2Colors = colors // {
    accent_rgb = "122, 162, 247";
    accent_strip = "7aa2f7";
    background_rgb = "26, 27, 38";
    foreground_rgb = "169, 177, 214";
  };

  renderTemplate = file:
    lib.foldlAttrs
      (text: name: value:
        builtins.replaceStrings [ "{{ ${name} }}" ] [ value ] text)
      (builtins.readFile file)
      phase2Colors;

  themed = name: "${upstream}/default/themed/${name}";

  tokyoNightBackground = pkgs.runCommand "nixarchy-tokyo-night-background" { } ''
    cp ${upstream}/themes/tokyo-night/backgrounds/omarchy.png $out
  '';
in {
  xdg.configFile = {
    "omarchy/current/background".source = tokyoNightBackground;
    "omarchy/current/theme/alacritty.toml".text = renderTemplate (themed "alacritty.toml.tpl");
    "omarchy/current/theme/btop.theme".text = renderTemplate (themed "btop.theme.tpl");
    "omarchy/current/theme/ghostty.conf".text = renderTemplate (themed "ghostty.conf.tpl");
    "omarchy/current/theme/gum.env.conf".text = renderTemplate (themed "gum.env.conf.tpl");
    "omarchy/current/theme/hyprland.conf".text = renderTemplate (themed "hyprland.conf.tpl");
    "omarchy/current/theme/hyprlock.conf".text = renderTemplate (themed "hyprlock.conf.tpl");
    "omarchy/current/theme/mako.ini".text = renderTemplate (themed "mako.ini.tpl");
    "omarchy/current/theme/swayosd.css".text = renderTemplate (themed "swayosd.css.tpl");
    "omarchy/current/theme/walker.css".text = renderTemplate (themed "walker.css.tpl");
    "omarchy/current/theme/waybar.css".text = renderTemplate (themed "waybar.css.tpl");
  };
}
