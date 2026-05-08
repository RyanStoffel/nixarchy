{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  terminal = "alacritty";
  launcher = "wofi --show drun";
  workspaceBinds = builtins.concatLists (builtins.genList (i:
    let n = toString (i + 1);
    in [ "$mod, ${n}, workspace, ${n}" ]
  ) 9);
in {
  home.packages = with pkgs; [ alacritty wofi ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${system}.hyprland;
    xwayland.enable = true;

    # Phase 1 stub. The real Omarchy bindings and split config arrive in Phase 2.
    settings = {
      "$mod" = "SUPER";

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration.rounding = 6;

      bind = [
        "$mod, RETURN, exec, ${terminal}"
        "$mod, SPACE, exec, ${launcher}"
        "$mod, Q, killactive,"
        "$mod SHIFT, Q, exit,"
      ] ++ workspaceBinds;
    };
  };
}
