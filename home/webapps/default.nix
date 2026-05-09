{ pkgs, ... }:
let
  chromium = "${pkgs.chromium}/bin/chromium";
  mkWebApp = name: url: ''
    [Desktop Entry]
    Type=Application
    Name=${name}
    GenericName=Web App
    Exec=${chromium} --new-window --app=${url}
    Terminal=false
    Categories=Network;
  '';
in {
  xdg.dataFile = {
    "applications/claude.desktop".text = mkWebApp "Claude" "https://claude.ai";
    "applications/chatgpt.desktop".text = mkWebApp "ChatGPT" "https://chatgpt.com";
    "applications/gemini.desktop".text = mkWebApp "Gemini" "https://gemini.google.com";
    "applications/youtube.desktop".text = mkWebApp "YouTube" "https://youtube.com";
    "applications/teams.desktop".text = mkWebApp "Microsoft Teams" "https://teams.microsoft.com/v2/";
    "applications/slack.desktop".text = mkWebApp "Slack" "https://app.slack.com/client";
  };
}
