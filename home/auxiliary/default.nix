{ inputs, pkgs, ... }:
let
  upstream = inputs.omarchy-upstream;

  patchFastfetch = text:
    builtins.replaceStrings
      [
        "~/.config/omarchy/branding/about.txt"
        ''version=$(omarchy-version); echo "Omarchy $version"''
        ''branch=$(omarchy-version-branch); echo "$branch"''
        ''channel=$(omarchy-version-channel); echo "$channel"''
        ''theme=$(omarchy-theme-current);''
        ''updated=$(omarchy-version-pkgs); echo "$updated"''
      ]
      [
        "~/.config/omarchy/branding/about.txt"
        ''echo "Nixarchy 3.1.0-phase2"''
        ''echo "feat/phase-2-configs-ported"''
        ''echo "nixos-unstable"''
        ''theme="Tokyo Night";''
        ''echo "Managed by Nix"''
      ]
      text;
in {
  home.packages = with pkgs; [
    btop
    fastfetch
    swayosd
  ];

  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service.ExecStart = "${pkgs.swayosd}/bin/swayosd-server";

    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile = {
    "btop/btop.conf".text = builtins.readFile "${upstream}/config/btop/btop.conf";
    "btop/themes/current.theme".text = builtins.readFile "${upstream}/themes/tokyo-night/btop.theme";
    "fastfetch/config.jsonc".text = patchFastfetch (builtins.readFile "${upstream}/config/fastfetch/config.jsonc");
    "omarchy/branding/about.txt".text = ''
      Nixarchy
      3.1.0-phase2
    '';
    "swayosd/config.toml".text = builtins.readFile "${upstream}/config/swayosd/config.toml";
    "swayosd/style.css".text = builtins.readFile "${upstream}/config/swayosd/style.css";
  };
}
