{ self, pkgs, ... }: {
  image.fileName = "nixarchy-3.0.0-phase1-x86_64-linux.iso";
  isoImage.contents = [{
    source = self;
    target = "/nixarchy";
  }];

  boot.zfs.forceImportRoot = false;

  environment.systemPackages = with pkgs; [
    git
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
