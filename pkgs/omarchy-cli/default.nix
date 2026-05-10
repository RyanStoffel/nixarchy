{ stdenv
, lib
, makeWrapper
, src
, walker
, libnotify
, xdg-utils
, xdg-terminal-exec
, hyprland
, power-profiles-daemon
, brightnessctl
, playerctl
, pamixer
, wl-clipboard
, grim
, slurp
, swappy
, gpu-screen-recorder
, jq
, gnome-calculator
, v4l-utils
, glib
, swayosd
}:

stdenv.mkDerivation {
  pname = "omarchy-cli";
  version = "unstable-${src.shortRev or src.rev or "dirty"}";
  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/omarchy
    cp -r bin/. $out/bin/
    cp -r applications config default migrations themes $out/share/omarchy/
    install -m644 icon.png version $out/share/omarchy/
    chmod +x $out/bin/omarchy*

    for script in $out/bin/omarchy $out/bin/omarchy-*; do
      [ -f "$script" ] || continue
      wrapProgram "$script" \
        --set OMARCHY_PATH "$out/share/omarchy" \
        --set OMARCHY_BIN "$out/bin" \
        --prefix PATH : ${lib.makeBinPath [
          walker
          libnotify
          xdg-utils
          xdg-terminal-exec
          hyprland
          power-profiles-daemon
          brightnessctl
          playerctl
          pamixer
          wl-clipboard
          grim
          slurp
          swappy
          gpu-screen-recorder
          jq
          gnome-calculator
          v4l-utils
          glib
          swayosd
        ]}
    done

    runHook postInstall
  '';

  meta = {
    description = "Omarchy helper scripts (wrapped for NixOS)";
    homepage = "https://github.com/basecamp/omarchy";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
