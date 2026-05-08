{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Terminals and launchers
    alacritty
    foot
    ghostty
    kitty
    rofi
    wofi

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
    tesseract
    xournalpp

    # Development
    cmake
    docker
    docker-compose
    gcc
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
    pkg-config
    python3
    rustup
    uv

    # TODO: Add Phase 3+ packages later: walker, omarchy-nvim, omarchy CLI, custom AUR ports.
    # TODO: Consider unfree apps only after explicit allowlisting: obsidian, spotify, typora, 1password-beta.
  ];
}
