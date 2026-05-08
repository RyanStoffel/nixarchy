{ ... }: {
  # Replace this with your machine's generated hardware config:
  # nixos-generate-config --root /mnt --show-hardware-config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
