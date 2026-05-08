# Nixarchy

Nixarchy is a NixOS port of basecamp/omarchy. This repo is currently Phase 1: a bootable flake with NixOS, SDDM, Hyprland, home-manager, and a starter base package set.

Status: Phase 1 - bootable skeleton. No themes, no `omarchy-*` CLI yet. See `DESIGN.md`.

## Install

```sh
# On a fresh NixOS install, booted from the official ISO with partitions mounted at /mnt:
nixos-generate-config --root /mnt

# Replace /mnt/etc/nixos/ with this flake:
mv /mnt/etc/nixos /mnt/etc/nixos.bak
git clone <repo> /mnt/etc/nixos

# Copy the generated hardware config into the flake:
cp /mnt/etc/nixos.bak/hardware-configuration.nix /mnt/etc/nixos/hosts/

# Edit flake.nix to set your hostname and username, if needed.
nixos-install --flake /mnt/etc/nixos#nixarchy
```

## Switch After Install

```sh
sudo nixos-rebuild switch --flake .#nixarchy
```

## Layout

Phase 1 includes only the directories needed for the bootable skeleton plus placeholders for visible future structure. `pkgs/`, `themes/`, `installer/`, and `lib/` are placeholders for later phases.

## What's Next

Continue with `DESIGN.md` Section 15 and Section 17 step 6 onward.
