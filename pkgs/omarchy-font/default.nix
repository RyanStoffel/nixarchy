{ stdenvNoCC, src }:

stdenvNoCC.mkDerivation {
  pname = "omarchy-font";
  version = "3.8.0";

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 ${src}/config/omarchy.ttf $out/share/fonts/truetype/omarchy.ttf

    runHook postInstall
  '';
}
