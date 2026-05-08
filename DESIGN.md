# Nixarchy — Omarchy on NixOS

A hybrid port of [basecamp/omarchy](https://github.com/basecamp/omarchy) v3.8.0 to NixOS, preserving the visual identity, theme system, and `omarchy-*` CLI surface while replacing Arch's imperative install layer with a declarative Nix flake.

> **Status:** Design doc. Working name "Nixarchy" — change before publishing.

---

## 1. Goals and non-goals

### Goals

1. A NixOS configuration that produces the same desktop experience as Omarchy: Hyprland, Waybar, SDDM, Plymouth, the same default keybindings, the same look, the same theme set.
2. Theme switching that feels instant, not a `nixos-rebuild`.
3. The `omarchy` CLI works (`omarchy theme set`, `omarchy refresh-config`, `omarchy capture screenshot`, etc.) — at least for everything that isn't tied to pacman.
4. Same install story: one curl-piped command on a fresh machine produces a working desktop.
5. Hardware support parity for the laptops Omarchy targets (Framework, Asus ROG, Dell XPS, T2 Macs, Surface).
6. Stay close enough to upstream that we can pull theme/config changes from `basecamp/omarchy` without rewriting them every release.

### Non-goals

1. **Bit-for-bit Arch behavior.** We will not reimplement `pacman`, AUR, or limine-snapper-sync. NixOS has its own answers (generations, flake inputs, btrfs+impermanence) that are strictly better at what those tools do.
2. **Mutating `/etc` and `/usr` from bash scripts at install time.** Anything that touches system files moves into the Nix module layer. This is the single biggest behavioral break from Omarchy.
3. **Supporting non-flakes.** This is a flake. No `configuration.nix`-only path.
4. **A "stable" release cadence matching Omarchy's.** We track Omarchy's `master` and pull theme/config updates as they land; system-level updates follow nixos-unstable or 24.11 (TBD, see §11).

---

## 2. Architecture overview

Three layers, in order from least mutable to most mutable:

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: ~/.config/omarchy/ (mutable, per-user)             │
│   - current/theme/ (active theme, hot-swappable)            │
│   - themes/ (user theme overrides)                          │
│   - branding/ (custom logo/about text)                      │
│   - written by `omarchy-*` CLI commands at runtime          │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ symlinked from / read by
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: home-manager (declarative, per-user dotfiles)      │
│   - ~/.config/hypr/, waybar/, alacritty/, ghostty/, etc.    │
│   - source files mostly verbatim from Omarchy's config/     │
│   - generated from flake on `home-manager switch`           │
└─────────────────────────────────────────────────────────────┘
                            ▲
                            │ depends on packages from
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: NixOS modules (declarative, system-level)          │
│   - Hyprland, SDDM, Plymouth, pipewire, bluetooth, etc.     │
│   - hardware quirks, kernel modules, boot loader            │
│   - the `omarchy-cli` derivation (282 bash scripts in /run) │
└─────────────────────────────────────────────────────────────┘
```

**The split is deliberate.** Layer 1 is what `nixos-rebuild` owns and Nix evaluates. Layer 2 is what `home-manager` owns. Layer 3 is the only mutable state we keep, and it exists for one reason: theme switching has to feel instant. Everything in Layer 3 is reproducible from the flake — losing it just means re-running `omarchy theme set <name>`.

---

## 3. Repository layout

```
nixarchy/
├── flake.nix                    # entry point, inputs/outputs
├── flake.lock
├── README.md
├── DESIGN.md                    # this document
│
├── modules/                     # NixOS modules
│   ├── default.nix              # imports all sub-modules
│   ├── desktop/
│   │   ├── hyprland.nix
│   │   ├── sddm.nix
│   │   ├── plymouth.nix
│   │   ├── waybar.nix           # only the systemd user service bits
│   │   └── audio.nix            # pipewire, wireplumber
│   ├── system/
│   │   ├── boot.nix             # systemd-boot (replaces limine)
│   │   ├── btrfs.nix            # optional btrfs+snapshots
│   │   ├── networking.nix       # iwd or NetworkManager
│   │   ├── bluetooth.nix
│   │   ├── printing.nix         # cups
│   │   ├── docker.nix
│   │   ├── fonts.nix
│   │   └── locale.nix
│   ├── hardware/                # mostly thin wrappers around nixos-hardware
│   │   ├── default.nix          # auto-detection helpers
│   │   ├── framework.nix
│   │   ├── asus-rog.nix
│   │   ├── dell-xps.nix
│   │   ├── apple-t2.nix
│   │   ├── surface.nix
│   │   └── nvidia.nix
│   └── omarchy-cli/             # the omarchy-* command derivation
│       ├── default.nix          # builds the package
│       └── overrides.nix        # nix-specific replacements (omarchy-pkg-add, etc.)
│
├── home/                        # home-manager modules
│   ├── default.nix
│   ├── hyprland/                # hypr/, hypridle, hyprlock
│   ├── waybar/
│   ├── terminals/               # alacritty, ghostty, kitty, foot
│   ├── walker/
│   ├── mako/
│   ├── shell/                   # bash, starship, tmux, zoxide, fzf
│   ├── editors/                 # nvim default config (omarchy-nvim)
│   └── theme.nix                # theme overlay logic, see §6
│
├── pkgs/                        # custom derivations
│   ├── default.nix              # overlay
│   ├── omarchy-cli/             # the bash CLI as a derivation
│   ├── omarchy-walker/          # walker config bundle
│   ├── omarchy-nvim/            # neovim config bundle
│   ├── plymouth-theme-omarchy/  # Plymouth theme
│   ├── sddm-theme-omarchy/      # SDDM theme
│   ├── aether/                  # AUR package, build from source
│   ├── cliamp/                  # AUR package
│   ├── tobi-try/                # AUR package
│   ├── voxtype/                 # AUR package
│   └── asdcontrol/              # AUR package, C build
│
├── themes/                      # 19 themes, ported verbatim
│   ├── tokyo-night/
│   │   ├── colors.toml
│   │   ├── btop.theme
│   │   ├── neovim.lua
│   │   └── ...
│   └── ... (catppuccin, gruvbox, nord, etc.)
│
├── assets/                      # branding, logos, wallpapers, icons
│   ├── icon.png
│   ├── icon.txt
│   ├── logo.svg
│   ├── logo.txt
│   ├── omarchy.ttf
│   └── applications/icons/
│
├── installer/                   # ISO + first-run wizard
│   ├── iso.nix                  # nixos-generators config
│   ├── installer.nix            # the live ISO config
│   └── first-run/               # post-install wizard scripts
│
└── lib/
    ├── default.nix              # custom lib functions
    ├── theme-template.nix       # the {{ var }} substitution engine
    └── mkScript.nix             # helper to wrap a bash script as a derivation
```

---

## 4. The flake

```nix
{
  description = "Nixarchy — Omarchy on NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    hyprland.url = "github:hyprwm/Hyprland";
    walker.url = "github:abenz1267/walker";
    omarchy-upstream = {
      url = "github:basecamp/omarchy";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosModules.default = ./modules;
    homeManagerModules.default = ./home;
    overlays.default = import ./pkgs;

    nixosConfigurations = {
      nixarchy = nixpkgs.lib.nixosSystem { ... };
      iso = nixpkgs.lib.nixosSystem { ... };
    };

    packages.x86_64-linux = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ self.overlays.default ];
      };
    in {
      omarchy-cli = pkgs.omarchy-cli;
      iso = self.nixosConfigurations.iso.config.system.build.isoImage;
      default = self.packages.x86_64-linux.iso;
    };
  };
}
```

The `omarchy-upstream` flake input pinned to `basecamp/omarchy` lets us pull config files from upstream at build time without forking them. This is how we stay current with theme/config changes (see §11).

---

## 5. Mapping Omarchy → Nixarchy

A pass through every install stage in Omarchy and where it lands here.

| Omarchy stage | Becomes | Notes |
|---|---|---|
| `install/preflight/guard.sh` | dropped | Nix's installer is the gate |
| `install/preflight/pacman.sh` | dropped | no pacman |
| `install/preflight/migrations.sh` | retained, scoped | only migrations that touch `~/.config/omarchy/` |
| `install/packaging/base.sh` | `modules/system/packages.nix` | 210 packages → `environment.systemPackages` |
| `install/packaging/fonts.sh` | `modules/system/fonts.nix` | + custom omarchy.ttf as a pkg |
| `install/packaging/nvim.sh` | `pkgs/omarchy-nvim/` | as a derivation |
| `install/packaging/icons.sh` | `home/icons.nix` | symlinked via home-manager |
| `install/packaging/webapps.sh` | `home/webapps.nix` | desktop file generators |
| `install/packaging/tuis.sh` | `home/tuis.nix` | same pattern |
| `install/packaging/asus-rog.sh` | `modules/hardware/asus-rog.nix` | conditional on hostname/profile |
| `install/packaging/framework16.sh` | `modules/hardware/framework.nix` | uses nixos-hardware |
| `install/packaging/surface.sh` | `modules/hardware/surface.nix` | uses nixos-hardware |
| `install/packaging/dell-xps-touchpad-haptics.sh` | `modules/hardware/dell-xps.nix` | custom kernel module |
| `install/config/theme.sh` | bootstrap script in `omarchy-cli` | runs once on first activation |
| `install/config/git.sh` | dropped | user does this themselves |
| `install/config/docker.sh` | `modules/system/docker.nix` | `virtualisation.docker.enable` |
| `install/config/timezones.sh` | `modules/system/locale.nix` | declarative |
| `install/config/increase-*-limit.sh` | `modules/system/limits.nix` | `security.pam.loginLimits` |
| `install/config/hardware/*` | `modules/hardware/*` | nearly all consolidated |
| `install/config/hardware/nvidia.sh` | `modules/hardware/nvidia.nix` | uses standard NixOS nvidia options |
| `install/login/sddm.sh` | `modules/desktop/sddm.nix` | declarative SDDM config |
| `install/login/plymouth.sh` | `modules/desktop/plymouth.nix` | with `pkgs.plymouth-theme-omarchy` |
| `install/login/limine-snapper.sh` | dropped | NixOS generations replace it |
| `install/login/hibernation.sh` | `modules/system/hibernation.nix` | declarative swap+resume |
| `install/login/default-keyring.sh` | `modules/desktop/keyring.nix` | `services.gnome.gnome-keyring.enable` |
| `install/post-install/pacman.sh` | dropped | |
| `install/first-run/welcome.sh` | `installer/first-run/` | runs once after first boot |
| `install/first-run/wifi.sh` | `installer/first-run/` | iwd/nmtui prompt |
| `install/first-run/firewall.sh` | `modules/system/firewall.nix` | always on, declarative |
| `bin/omarchy-*` (282 scripts) | `pkgs/omarchy-cli/` | see §7 |
| `migrations/*.sh` | `pkgs/omarchy-cli/migrations/` | only user-state migrations |
| `config/**` | `home/**` | mostly verbatim |
| `default/**` | exposed via `OMARCHY_PATH` env var pointing at the store | see §6 |
| `themes/**` | `themes/**` | verbatim, exposed via `OMARCHY_THEMES_PATH` |

The big wins: ~25 install scripts disappear because Nix does that thing better. The big losses: `omarchy-pkg-add` semantics change (see §7).

---

## 6. The theme system

This is the most interesting part of Omarchy and the part where NixOS hurts most. Omarchy's flow:

1. User runs `omarchy theme set "Tokyo Night"`.
2. `omarchy-theme-set` builds `~/.config/omarchy/next-theme/` from `themes/tokyo-night/` plus user overrides in `~/.config/omarchy/themes/tokyo-night/`.
3. It runs `omarchy-theme-set-templates` which iterates over `default/themed/*.tpl`, substitutes `{{ background }}`, `{{ color0 }}`, etc. from `colors.toml`, and writes the result into `~/.config/omarchy/next-theme/`.
4. Atomic rename: `next-theme` → `current/theme`.
5. Restart waybar, mako, swayosd, btop, terminals, etc.
6. Apps that read from `~/.config/omarchy/current/theme/` (waybar, mako, alacritty, hyprland) pick up the change.

This is fundamentally imperative. Nix can render every theme at build time, but switching them by rebuilding takes 10+ seconds and is the wrong UX.

### Decision: keep imperative theme switching, store theme outputs in the Nix store

The flake produces one derivation per theme:

```
/nix/store/abc...-nixarchy-theme-tokyo-night/
├── colors.toml
├── btop.theme
├── alacritty.toml         # rendered from .tpl at build time
├── hyprland.conf          # rendered from .tpl at build time
├── waybar.css             # rendered from .tpl at build time
├── mako.ini               # rendered from .tpl at build time
└── ...
```

Templates are rendered **at flake-build time** by a Nix function that reads `colors.toml` and substitutes `{{ var }}`. No bash templating at runtime; the rendered files are immutable in the store.

`omarchy-theme-set` then becomes a pure copy operation:

```bash
cp -r /run/current-system/sw/share/nixarchy/themes/tokyo-night/* ~/.config/omarchy/current/theme/
```

Each app's home-manager config points at `~/.config/omarchy/current/theme/<app>` so swapping is just a directory rewrite + service restart. No rebuild required.

User overrides in `~/.config/omarchy/themes/<name>/` continue to work — they layer on top of the store-provided theme just like in Omarchy.

### Why this works

- Theme content is fully reproducible (it lives in the store).
- Theme switching is fast (it's a copy).
- Adding a custom theme means adding a directory to the flake or `~/.config/omarchy/themes/`.
- Templates are evaluated by Nix, not bash, so we can typecheck them.

### `lib/theme-template.nix` sketch

```nix
{ lib }:
let
  renderTemplate = colors: tpl:
    builtins.replaceStrings
      (map (k: "{{ ${k} }}") (builtins.attrNames colors))
      (builtins.attrValues colors)
      tpl;

  parseColorsToml = path: ...; # use builtins.fromTOML

  mkTheme = { name, src, templates }:
    let
      colors = parseColorsToml "${src}/colors.toml";
      rendered = lib.mapAttrs (n: tpl: renderTemplate colors (builtins.readFile tpl)) templates;
    in
      pkgs.runCommand "nixarchy-theme-${name}" {} ''
        mkdir -p $out
        cp -r ${src}/* $out/
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: content:
          ''cat > $out/${n} <<'EOF'
          ${content}
          EOF''
        ) rendered)}
      '';
in { inherit mkTheme; }
```

(Real implementation will be cleaner — sketch is to show the shape.)

---

## 7. The `omarchy` CLI

282 bash scripts. The good news: most of them are pure (theme manipulation, hardware detection, file copies, restart helpers). The hard cases are anything that touches packages.

### Packaging strategy

A single derivation `omarchy-cli` that:

1. Takes all 282 scripts from `bin/` (sourced from the upstream flake input).
2. Patches a small set of them to use Nix-aware replacements.
3. Wraps every script with `makeWrapper` to set `OMARCHY_PATH`, `OMARCHY_THEMES_PATH`, `OMARCHY_BIN`, etc. to the right store paths.
4. Installs to `$out/bin/`.

```nix
omarchy-cli = pkgs.stdenv.mkDerivation {
  pname = "omarchy-cli";
  version = "3.8.0-nix";
  src = inputs.omarchy-upstream;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  postPatch = ''
    cp -r ${./overrides}/* bin/
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/nixarchy
    cp -r bin/* $out/bin/
    cp -r default themes config $out/share/nixarchy/

    for script in $out/bin/omarchy-*; do
      wrapProgram "$script" \
        --set OMARCHY_PATH $out/share/nixarchy \
        --set OMARCHY_BIN $out/bin \
        --prefix PATH : ${lib.makeBinPath [ pkgs.gum pkgs.jq pkgs.fzf ... ]}
    done
  '';
};
```

### The override list

These bin scripts get replaced with Nix-aware versions:

| Script | Why | What it does instead |
|---|---|---|
| `omarchy-pkg-add` | no pacman | prints a warning + suggests `nix profile install` or editing the flake |
| `omarchy-pkg-missing` | no pacman | uses `command -v` only |
| `omarchy-pkg-present` | no pacman | uses `command -v` only |
| `omarchy-update` | no system-update path | runs `nixos-rebuild switch --flake ...` |
| `omarchy-snapshot-*` | replaced by NixOS generations | wraps `nix-env --list-generations` |
| `omarchy-channel-set` | no Arch channels | switches between `nixpkgs-stable` and `nixpkgs-unstable` flake inputs |
| `omarchy-branch-set` | no pacman branches | switches between flake refs |
| `omarchy-migrate-*` | scoped | only user-state migrations |
| `omarchy-refresh-config` | source path differs | reads from `$OMARCHY_PATH/config/` (store) |

Everything else runs unmodified — `omarchy-theme-set`, `omarchy-capture-screenshot`, `omarchy-restart-waybar`, all 200+ helper utilities.

### Behavioral break to flag clearly

`omarchy-pkg-add jq` doesn't install jq. On NixOS it can't, not without imperative-side-channel hacks like nix-env that we don't want users in. The replacement script will:

1. Check if `jq` is on PATH already — if yes, exit 0.
2. If not, print:
   ```
   Nixarchy doesn't install packages imperatively.
   Add `jq` to your flake's `environment.systemPackages` and run:
     sudo nixos-rebuild switch --flake ~/.config/nixarchy
   Or for a one-shot user install:
     nix profile install nixpkgs#jq
   ```
3. Exit 1.

This is a real UX regression for users coming from Omarchy. We document it prominently in the README and in the welcome message.

---

## 8. Boot, kernel, snapshots

| Concern | Omarchy | Nixarchy |
|---|---|---|
| Bootloader | Limine | systemd-boot (default), GRUB optional |
| Snapshots | btrfs + snapper + limine-snapper-sync | NixOS generations (always on) + optional btrfs snapshots via `services.btrbk` |
| Rollback | Boot menu shows snapper snapshots | Boot menu shows NixOS generations |
| Kernel | `linux` (Arch) or `linux-t2` etc. | `pkgs.linuxPackages` (latest stable) by default; `linuxPackages_zen` etc. configurable per-host |
| initrd | mkinitcpio with custom hooks | nixos default initrd; `boot.initrd.systemd.enable = true;` |
| Plymouth | custom omarchy theme | same theme, packaged as `pkgs.plymouth-theme-omarchy` |

### Why drop limine + snapper

NixOS gives you better rollback than snapper-on-btrfs already. Every `nixos-rebuild switch` creates a generation that appears in the systemd-boot menu. Booting an older generation is a one-keypress operation. Trying to layer snapper on top means two competing snapshot systems and a more confused mental model. Users who specifically want btrbk for `/home` snapshots can opt in via a module flag.

---

## 9. Hardware modules

`nixos-hardware` covers most of what Omarchy's hardware scripts do. We import the relevant profile per machine type and add only the pieces nixos-hardware misses.

```nix
# modules/hardware/framework.nix
{ inputs, ... }: {
  imports = [ inputs.nixos-hardware.nixosModules.framework-13-7040-amd ];
  # Omarchy adds: fix-f13-amd-audio-input, qmk-hid
  # qmk-hid is a udev rule we ship verbatim
  services.udev.extraRules = builtins.readFile ../../assets/udev/qmk-hid.rules;
}
```

What's covered by nixos-hardware:
- Framework 13/16 (AMD and Intel variants)
- Asus ROG (general profile + asusctl service)
- Apple T2 (with apple-bcm-firmware, apple-t2-audio-config)
- Surface devices
- Dell XPS series

What we ship ourselves:
- The Dell XPS haptic touchpad daemon (`dell-xps-touchpad-haptics`) — needs packaging from source.
- The `asdcontrol` Apple Studio Display brightness tool — needs packaging.
- The `tuxedo-drivers-nocompatcheck-dkms` kernel module — packaged separately.
- The `intel-ipu7-camera` userspace + kernel module — Intel-specific, may need patching.
- The `yt6801-dkms` ethernet driver — DKMS module wrapping.

Hosts opt in:

```nix
# hosts/my-framework.nix
{
  imports = [
    ../modules
    ../modules/hardware/framework.nix
  ];
  networking.hostName = "frame";
}
```

---

## 10. The installer ISO

Omarchy's `boot.sh` assumes a vanilla Arch is already installed. We invert the model: ship a NixOS-based live ISO that runs an installer and writes out a flake.

Built with `nixos-generators`:

```nix
# installer/iso.nix
{
  imports = [
    ../modules/desktop/hyprland.nix
    ../modules/desktop/sddm.nix
  ];

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  services.getty.autologinUser = "nixos";

  systemd.services.nixarchy-installer = {
    description = "Nixarchy first-run installer";
    wantedBy = [ "graphical.target" ];
    serviceConfig.ExecStart = "${pkgs.nixarchy-installer}/bin/nixarchy-install";
  };
}
```

The installer itself is a TUI (gum-based, like Omarchy's first-run wizard) that:

1. Asks for hostname, username, password, timezone, keyboard layout.
2. Asks which hardware profile (framework / asus-rog / apple-t2 / generic).
3. Asks for disk and partitions it (uses `disko` for declarative disk layout).
4. Writes `/etc/nixarchy/configuration.nix` referencing the flake.
5. Runs `nixos-install --flake /etc/nixarchy#...`.
6. Reboots into the installed system.
7. On first boot, runs the equivalent of `install/first-run/welcome.sh`.

The ISO is built from the same flake — `nix build .#iso` produces a bootable image.

---

## 11. Tracking upstream Omarchy

We don't fork the bash scripts and themes wholesale; we pull them from upstream as a flake input.

```nix
inputs.omarchy-upstream = {
  url = "github:basecamp/omarchy/master";
  flake = false;
};
```

The `omarchy-cli` derivation reads its source from `${inputs.omarchy-upstream}/bin`. The themes come from `${inputs.omarchy-upstream}/themes`. The default configs come from `${inputs.omarchy-upstream}/default` and `${inputs.omarchy-upstream}/config`.

To pull upstream changes: `nix flake update omarchy-upstream`.

What we do **not** pull from upstream:
- Install scripts (we have our own)
- Migration scripts (we have our own scoped set)
- The `bin/omarchy-pkg-*` scripts (overridden, see §7)

What we **do** patch on the way through:
- Hardcoded `~/.local/share/omarchy/` paths get rewritten to the store path. Most scripts already use `$OMARCHY_PATH` so this is mostly already correct.

### Versioning

Nixarchy version = `<omarchy-version>-nix.<n>`. Example: `3.8.0-nix.1`. Bumping the omarchy input bumps the version number, which appears in `omarchy --version`.

### Channels

Equivalent to Omarchy's stable/rc/dev:

| Nixarchy channel | What it tracks |
|---|---|
| stable | Latest tagged release of `basecamp/omarchy` + nixos-24.11 |
| rc | `basecamp/omarchy@master` + nixos-unstable |
| dev | `basecamp/omarchy@dev` + nixos-unstable |

Switching channels = `omarchy channel set <name>`, which rewrites the flake's input refs and rebuilds.

---

## 12. First-run wizard

After install, on first login, we run the equivalent of Omarchy's `install/first-run/`:

| Script | Status |
|---|---|
| `welcome.sh` | keep — notify-send tour of keybindings |
| `wifi.sh` | keep — `iwctl` or `nmtui` prompt if no network |
| `gnome-theme.sh` | dropped — `services.gnome.glib-networking.enable` etc. handled declaratively |
| `firewall.sh` | dropped — UFW is in the system module, always on |
| `swayosd.sh` | dropped — systemd user service in module |
| `gtk-primary-paste.sh` | keep — gsettings call |
| `dns-resolver.sh` | dropped — `services.resolved.enable` |
| `battery-monitor.sh` | dropped — systemd user service in module |
| `recover-internal-monitor.sh` | keep — interactive |
| `cleanup-reboot-sudoers.sh` | dropped — never created in the first place |
| `elephant.sh` | keep — walker provider config |
| `install-voxtype.hook` | keep — opt-in install of voxtype daemon |

Total: ~5 scripts in first-run instead of 12. The rest moved up into the declarative layer.

---

## 13. What this gives up

Honest accounting of regressions vs. real Omarchy:

1. **`omarchy-pkg-add` doesn't install packages.** Workflow change for users.
2. **First boot is slower.** Nix has to evaluate the flake; expect 30–60 seconds extra on first activation.
3. **Disk usage is higher.** Nix store keeps old generations until you garbage-collect. Plan for ~10–20 GB more than Arch+snapper.
4. **Some AUR packages may not exist on Nix.** Each one has to be packaged manually. Tracked in §14.
5. **Limine boot menu prettiness is lost.** systemd-boot is functional but plain. (We can add a Plymouth-on-bootloader splash later.)
6. **You can't `pacman -S` something to debug.** You can `nix-shell -p` for a temporary shell, but it's a different muscle memory.

What we gain: atomic rollback, reproducibility, no dependency hell, the entire system declared in one git repo, deterministic builds, declarative secrets via sops/agenix, and the ability to spin up the same desktop on any other NixOS box with one flake reference.

---

## 14. Package inventory

Three buckets:

### A. In nixpkgs already (~180 of 210)

`alacritty`, `bat`, `btop`, `chromium`, `docker`, `eza`, `fastfetch`, `fd`, `firefox`, `fzf`, `ghostty`, `git`, `gnome-calculator`, `gnome-keyring`, `grim`, `hyprland`, `hypridle`, `hyprlock`, `hyprpicker`, `imagemagick`, `imv`, `jq`, `kdenlive`, `kitty`, `lazydocker`, `lazygit`, `libreoffice-fresh`, `localsend`, `mako`, `mpv`, `nautilus`, `neovim`, `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji`, `obsidian`, `obs-studio`, `pamixer`, `pinta`, `playerctl`, `plymouth`, `power-profiles-daemon`, `ripgrep`, `sddm`, `signal-desktop`, `slurp`, `spotify`, `starship`, `swaybg`, `swayosd`, `tesseract`, `tldr`, `tmux`, `typora`, `ufw`, `waybar`, `wireplumber`, `wl-clipboard`, `xournalpp`, `zoxide`, … (full list in `modules/system/packages.nix`).

### B. Need packaging from source (custom derivations in `pkgs/`)

| Package | Upstream | Notes |
|---|---|---|
| `aether` | github (basecamp tooling) | bash installer to figure out |
| `cliamp` | github | go binary, easy |
| `tobi-try` | github | unknown, investigate |
| `omarchy-walker` | basecamp fork of walker | packaged from flake input |
| `omarchy-nvim` | basecamp config for nvim | wrapper around nvim with config bundle |
| `voxtype` | github | systemd service |
| `asdcontrol` | github | small C build |
| `dell-xps-touchpad-haptics` | github | C + udev rules |
| `intel-ipu7-camera` | intel | userspace + kernel module |
| `yt6801-dkms` | motorcomm | DKMS kernel module |
| `tuxedo-drivers-nocompatcheck-dkms` | tuxedo | DKMS variant of tuxedo-drivers |
| `linux-ptl` | upstream patch set | kernel variant; may skip |
| `claude-code` | anthropic | already in nixpkgs as `claude-code` — verify |
| `1password-beta` | 1Password | unfree, beta channel; verify nixpkgs has it |

Roughly 13 custom derivations to write. Each is a few hours of work; expect 1–2 weekends.

### C. Replace or skip

- `yay` — no AUR, no need.
- `limine`, `limine-snapper-sync`, `limine-mkinitcpio-hook` — replaced by systemd-boot.
- `linux-t2`, `t2fanrd`, `tiny-dfr` — handled by Apple T2 nixos-hardware profile.
- `kernel-modules-hook` — Nix doesn't need this; modules are versioned with the kernel.

---

## 15. Phased delivery (revised)

| Phase | Deliverable | Estimated effort |
|---|---|---|
| 1 | Bootable flake: NixOS + Hyprland + SDDM + Plymouth + base packages. No themes, no CLI. | 1 weekend |
| 2 | Configs ported via home-manager: hypr/, waybar/, terminals/, mako/, walker/. Default keybindings work. | 1 weekend |
| 3 | Theme system: 19 themes packaged, template engine, `omarchy-theme-set` works. | 1 weekend |
| 4 | `omarchy` CLI: all 282 scripts wrapped, overrides for the package-ish ones. | 2 weekends |
| 5 | Hardware modules: framework, asus-rog, apple-t2, surface, dell-xps. | 1 weekend |
| 6 | Custom packages: 13 derivations from §14.B. | 2 weekends |
| 7 | Installer ISO: TUI installer, disko-based partitioning, first-run wizard. | 2 weekends |
| 8 | Polish: docs, CI for flake checks, automated upstream-input updates, theme test renders. | 1 weekend |

Realistic total: **8–10 weekends** of focused work for one person. Less if you're comfortable with Nix already; more if this is your first serious Nix project.

---

## 16. Open questions to resolve before writing code

1. **nixos-unstable vs. nixos-24.11 for stable channel?** Hyprland moves fast and 24.11 is often behind. Lean unstable, but call it explicitly.
2. **disko or manual partitioning in the installer?** disko is declarative and great, but adds a learning curve to the installer.
3. **Do we ship a binary cache?** Building from source is slow; a Cachix cache would let users pull pre-built derivations of our custom packages. Adds infra cost.
4. **Upstream tracking cadence — manual `nix flake update` or scheduled CI?** Auto-bumps catch breakage; manual is calmer.
5. **License.** Omarchy is MIT. We stay MIT. But we should ship a NOTICE that lists which code came from upstream verbatim and which is ours.
6. **Naming.** "Nixarchy" is a placeholder. Names that don't suck: `nixarchy`, `omanix`, `nixarch`, `omarchy-nix`. DHH may have opinions if this gets traction.

---

## 17. What I want to write first when we start coding

In strict order:

1. `flake.nix` skeleton with inputs and a single empty `nixosConfigurations.nixarchy`.
2. `modules/desktop/hyprland.nix` — the absolute minimum to get a Hyprland session.
3. `modules/desktop/sddm.nix` — login screen, no theme yet.
4. `modules/system/packages.nix` — drop the 180 trivially-mappable packages.
5. `home/default.nix` — empty home-manager scaffold.
6. `home/hyprland/default.nix` — port `config/hypr/hyprland.conf` and friends.

That gets us a bootable, ugly, but recognizably-Hyprland system inside one weekend. Phase 1 done. Then we layer up.

---*
