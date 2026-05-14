# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  networking.hostName = "blahaj";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_pstate=active" ];

  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest.override {
  #   argsOverride = rec {
  #     # Fetch the entire kernel tree from mkopec's bleeding-edge branch
  #     src = pkgs.fetchFromGitHub {
  #       owner = "mkopec";
  #       repo = "linux";
  #
  #       # update these two when looking to update the kernel
  #       rev = "1cac81ea1c86b194e4de3281890217c953d59033";
  #       hash = "sha256-6CQcVnJ0VqfXKfz/v1a0kJsifBfh0SDuZm5J/7tyRzM="; 
  #     };
  #
  #     # We override the version string so your system doesn't get confused 
  #     # by kernel module mismatches. (Adjust the '6.18.0' part if his branch 
  #     # has rebased to a newer mainline version since this writing).
  #     version = "7.0.0-rc1-mkopec-frl";
  #     modDirVersion = version;
  #   };
  # });
  # boot.kernelParams = [ "amd_pstate=active" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.userControlled.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Vilnius";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.stk = {
    isNormalUser = true;
    description = "Stanislovas";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "docker" "plugdev" "dialout" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQ35CctJE0EAAABaMp1l4dK5jMNRJ4Pvv9fQjN8J2W3 stk@gnocchi"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  boot.loader.systemd-boot.configurationLimit = 5;
  nix.gc.automatic = true;
  nix.gc.dates = "daily";
  nix.gc.options = "--delete-older-than 7d";

  # Enable audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.pulseaudio.enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # system utils
    cryptsetup
    parted
    docker-compose
    duplicity
    fastfetch
    imagemagick
    ncdu
    powertop
    udiskie
    udisks
    unzip
    usbutils
    v4l-utils
    v4l2-relayd
    pinentry-all
    
    # sway/wayland utils
    grim
    hyprlock
    i3status
    mako
    rofi
    slurp
    swayidle
    wl-clipboard
    wshowkeys

    # audio
    alsa-tools
    alsa-utils
    pa-notify
    pamixer
    pasystray
    pavucontrol
    
    # utils
    curl
    fd
    gnumake
    jq
    just
    nomacs
    playerctl
    tesseract
    tree
    wget

    # gaming
    amdgpu_top
    clpeak
    steam-run
    vulkan-tools
    mesa-demos
    gamescope
    mangohud
    piper

    # applications
    abcde
    acpica-tools
    alacritty
    alacritty-theme
    antigravity-fhs
    calibre
    deluge
    discord
    # freecad
    gimp
    git
    inkscape
    kicad
    obs-studio
    onlyoffice-desktopeditors
    trayscale
    thunderbird
    vlc
    blender

    # languages
    bun
    clang
    gcc
    lua-language-server
    nixd
    python313
    python313Packages.pip
    rustup
    stylua
    uv
    zig
    zsh
    ty

    # games
    lunar-client
    lutris

    # tv mode switcher
    (writeShellScriptBin "toggle-tv-mode" ''
      # Get current TTY
      CURRENT_TTY=$(cat /sys/class/tty/tty0/active | tr -dc '0-9')

      set_audio_default() {
        local search_name="$1"
        local node_id=$(wpctl status | grep -m 1 -i "$search_name" | awk -F'.' '{print $1}' | awk '{print $NF}')
        
        if [ -n "$node_id" ]; then
          wpctl set-default "$node_id"
          echo "Routed audio to $search_name (ID: $node_id)"
        else
          echo "Warning: Could not find audio device '$search_name'"
        fi
      }

      if [ "$CURRENT_TTY" -eq 1 ]; then
        echo "Switching to TV Mode..."
        pkill steam
        sleep 2 
        set_audio_default "Fosi Audio ZD3 Analog Stereo"

        # Using absolute paths injected by Nix to perfectly match sudo rules
        sudo ${pkgs.systemd}/bin/systemctl start tv-session.service
        sudo ${pkgs.kbd}/bin/chvt 8

      else
        echo "Switching to Desk Mode..."
        (
          sleep 1
          sudo ${pkgs.systemd}/bin/systemctl stop tv-session.service
          set_audio_default "ArturiaMsd Analog Stereo"
          sudo ${pkgs.kbd}/bin/chvt 1
          nohup steam > /dev/null 2>&1 &
        ) </dev/null >/dev/null 2>&1 & disown
      fi
    '')
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.monofur
    corefonts
    vista-fonts
  ];

  programs.zsh = {
    enable = true;
  };

  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  programs.firefox = {
    enable = true;
    package = pkgs.firefox-bin;
  };

  programs.wshowkeys.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    enableSSHSupport = true;
  };

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.openFirewall = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  systemd.timers."backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2 hours";
      OnUnitActiveSec = "2 hours";
      Unit = "incremental-backup.service";
    };
  };

  systemd.services."incremental-backup" = {
    script = ''
      ${pkgs.duplicity}/bin/duplicity incremental \
        --encrypt-sign-key B64C29A6 \
        --exclude /home/stk/.cache \
        --exclude /home/stk/.mozilla \
        --exclude /home/stk/.steam \
        --exclude /home/stk/.bun \
        --exclude /home/stk/.local/share/Steam \
        --exclude /home/stk/Games \
        /home/stk \
        scp://girlboss//mnt/newtent/stk/blahaj
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "stk";
    };
    environment = {
      PASSPHRASE = "";
    };
  };

  systemd.services."full-backup" = {
    script = ''
      ${pkgs.duplicity}/bin/duplicity full \
        --encrypt-sign-key B64C29A6 \
        --exclude /home/stk/.cache \
        --exclude /home/stk/.mozilla \
        --exclude /home/stk/.steam \
        --exclude /home/stk/.bun \
        --exclude /home/stk/.local/share/Steam \
        --exclude /home/stk/Games \
        /home/stk \
        scp://girlboss//mnt/newtent/stk/blahaj
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "stk";
    };
    environment = {
      PASSPHRASE = "";
    };
  };

  systemd.services.tv-session = {
    description = "Gamescope TV Session";
    # Ensure it doesn't conflict with a login prompt
    conflicts = [ "getty@tty8.service" ]; 
    
    serviceConfig = {
      User = "stk"; # REPLACE WITH YOUR USERNAME
      PAMName = "login";
      TTYPath = "/dev/tty8";
      StandardInput = "tty";
      StandardOutput = "journal";
      StandardError = "journal";
      UtmpIdentifier = "tty8";
      UtmpMode = "user";
      Type = "simple";

      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
      
      # The magic command. Adjust the -W and -H to your TV's resolution. 
      # You may need to verify the output name (-O) is exactly HDMI-A-1 using swaymsg -t get_outputs
      ExecStart = "${pkgs.gamescope}/bin/gamescope -e -W 3840 -H 2160 -r 60 -O HDMI-A-1 -- ${pkgs.libcap}/bin/capsh --caps= -- -c 'exec ${pkgs.steam}/bin/steam -gamepadui'";
      Restart = "no";
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  services.blueman.enable = true;

  services.gnome.gnome-keyring.enable = true;

  services.gvfs.enable = true;

  services.udisks2.enable = true;

  services.tumbler.enable = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  services.keyd = {
    enable = true;
    keyboards = {
      # The name is just the name of the configuration file, it does not really matter
      default = {
        ids = [ "*" ]; # what goes into the [id] section, here we select all keyboards
        # Everything but the ID section:
        settings = {
          # The main layer, if you choose to declare it in Nix
          main = {
            capslock = "overload(control, esc)"; # you might need to also enclose the key in quotes if it contains non-alphabetical symbols
          };
          otherlayer = {};
        };
        extraConfig = ''
          # put here any extra-config, e.g. you can copy/paste here directly a configuration, just remove the ids part
        '';
      };
    };
  };

  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.swayfx}/bin/sway";
        user = "stk";
      };
      default_session = initial_session;
    };
  };

  services.ratbagd.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PasswordAuthentication = false;
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "stk" ];
      commands = [
        { command = "${pkgs.kbd}/bin/chvt"; options = [ "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl start tv-session.service"; options = [ "NOPASSWD" ]; }
        { command = "${pkgs.systemd}/bin/systemctl stop tv-session.service"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    6969 8000 8080  # development stuff
  ];

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
