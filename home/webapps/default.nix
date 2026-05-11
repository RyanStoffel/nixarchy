{ config, lib, pkgs, ... }:
let
  chromium = "${pkgs.chromium}/bin/chromium";
  iconDir = "${config.home.homeDirectory}/.local/share/applications/icons";

  webapps = {
    claude = { name = "Claude"; url = "https://claude.ai"; domain = "claude.ai"; };
    chatgpt = { name = "ChatGPT"; url = "https://chatgpt.com"; domain = "chatgpt.com"; };
    gemini = { name = "Gemini"; url = "https://gemini.google.com"; domain = "gemini.google.com"; };
    youtube = { name = "YouTube"; url = "https://youtube.com"; domain = "youtube.com"; };
    teams = { name = "Microsoft Teams"; url = "https://teams.microsoft.com/v2/"; domain = "teams.microsoft.com"; };
    slack = { name = "Slack"; url = "https://app.slack.com/client"; domain = "slack.com"; };
  };

  mkWebApp = wa: ''
    [Desktop Entry]
    Type=Application
    Name=${wa.name}
    GenericName=Web App
    Exec=${chromium} --new-window --app=${wa.url}
    Terminal=false
    Icon=${iconDir}/${wa.name}.png
    Categories=Network;
  '';
in {
  xdg.dataFile = lib.mapAttrs' (key: wa:
    lib.nameValuePair "applications/${key}.desktop" { text = mkWebApp wa; }
  ) webapps;

  home.activation.fetchWebappIcons = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    iconDir="${iconDir}"
    $DRY_RUN_CMD mkdir -p "$iconDir"
    fetch() {
      local target="$iconDir/$1.png"
      if [[ -s $target ]]; then return 0; fi
      ${pkgs.curl}/bin/curl -fsSL --max-time 5 -o "$target" \
        "https://www.google.com/s2/favicons?domain=$2&sz=128" 2>/dev/null \
        || rm -f "$target"
    }
    ${lib.concatStringsSep "\n    " (lib.mapAttrsToList (_: wa:
      ''fetch "${wa.name}" "${wa.domain}"''
    ) webapps)}
  '';
}
