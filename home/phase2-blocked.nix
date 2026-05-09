{ pkgs, ... }:
let
  phase2Blocked = pkgs.writeShellScriptBin "nixarchy-phase2-blocked" ''
    name="$1"
    shift || true

    message="$name is not available in Nixarchy Phase 2. This depends on a later phase."
    printf '%s\n' "$message" >&2

    if command -v notify-send >/dev/null 2>&1; then
      notify-send -u critical "Nixarchy Phase 2" "$message"
    fi

    exit 1
  '';
in {
  home.packages = [ phase2Blocked ];
}
