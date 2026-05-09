{ lib, pkgs, username ? "nixarchy", ... }: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "1password"
      "claude-code"
      "discord"
      "spotify"
      "steam"
      "steam-original"
      "steam-run"
      "steam-unwrapped"
      "vscode"
    ];

  virtualisation.docker.enable = true;
  users.users.${username}.extraGroups = [ "docker" ];
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    # Terminals and launchers
    alacritty
    foot
    ghostty
    kitty
    rofi

    # Shell tools
    bashInteractive
    direnv
    fish
    fzf
    starship
    tmux
    zoxide
    zsh

    # File and text utilities
    bat
    curl
    eza
    fd
    file
    gnupg
    jq
    just
    openssl
    p7zip
    ripgrep
    rsync
    tree
    unzip
    wget
    which
    zip

    # Media and desktop utilities
    brightnessctl
    cliphist
    ffmpeg
    grim
    hypridle
    hyprlock
    hyprpicker
    imagemagick
    imv
    libnotify
    mako
    mpv
    pamixer
    pavucontrol
    playerctl
    slurp
    swaybg
    swappy
    waybar
    wf-recorder
    wl-clipboard

    # System tools
    btop
    dnsutils
    fastfetch
    htop
    iproute2
    lm_sensors
    lshw
    networkmanagerapplet
    nmap
    parted
    pciutils
    smartmontools
    usbutils

    # Applications
    chromium
    discord
    evince
    file-roller
    firefox
    gnome-calculator
    gnome-keyring
    kdePackages.kdenlive
    libreoffice-fresh
    localsend
    nautilus
    obs-studio
    pinta
    signal-desktop
    spotify
    tesseract
    _1password-gui
    xournalpp

    # Development
    cmake
    claude-code
    codex
    docker
    docker-compose
    gcc
    gemini-cli
    gh
    git
    git-lfs
    gnumake
    go
    helix
    lazydocker
    lazygit
    neovim
    nodejs_22
    opencode
    pkg-config
    python3
    rustup
    uv
    vscode
    zed-editor

    # TODO: Add Phase 3+ packages later: omarchy-nvim, omarchy CLI, custom AUR ports.
    # TODO: Consider unfree apps only after explicit allowlisting: obsidian, typora.
  ];
}
