{
  config,
  pkgs,
  lib,
  user,
  ...
}:
{
  # Import /etc/nixos/hardware-configuration.nix when present on the target machine
  imports = lib.optional (builtins.pathExists /etc/nixos/hardware-configuration.nix) /etc/nixos/hardware-configuration.nix;

  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  networking.hostName = "homelab";
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [
      53
      config.services.tailscale.port
    ];
    allowedTCPPorts = [
      22
      53
      80
      443
      3000
    ];
  };

  # Ensure systemd-resolved does not bind port 53 needed by AdGuard Home
  services.resolved.enable = false;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      user
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDx0SFnNuN+Bx/e5eMy0inoh/GOwyKiviyOzb45D8YJ45h0F0Mcmgryb+v55z1eGeBZw0GsnrxrPXTw2uz1r26nGxLhtD9pRnDBMCRUR08KM287I6X2/vSKu3eaKwh78WdcKj3f5H4Zq2LomFAF5BZSCAzQ697JxIQqF3m/sbZ1x9iyh4Fw5Rr3wcKgeurRW9l8r+BAwO6CROWNM9N826x2rgMjfWtwmQyCKpJ0lLelqT+b91wI1MGYJs+m18hwnENCAD8sXarciSvq7+IzME9qCuPQR4BBFTTp26jVXOEMlNeGyRPlhAN725Wf8qPuapTkFqrqL9FwC56x0EWT7X6hOjxPRmJPMP3oWWI6Hjac3Aw8Y/fy4qAbYrhauhctI7YT3mMGrNsU94AP65uPyyYKFrZdGAoN0hULwg3u9HVB9aATBauNhQ7eIWODkyv7s/oGuQvvsKTmd0p3r6m58kLuIYuhSBIljllFGGCsKUcxWJBTGhxZ0YouuWGzr3Nb9D78Z6KWgI5jcb56wYVVaGH1bQlH6MkpeuREaSj6SEuY9pgIClq/6WmLzwRxOLBPL9QVsFFkRkP2BtSnrasinUJESkWcjvpcPkV0GQ5spLd3mnGXNk9iIBwN/JdRl6WMZX53LkSikSTztlsr9Lx6usCERLY/eeIeptKBoX2rh3gETQ== openpgp:0x04C216BA"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  # 1. AdGuard Home (DNS on :53 + Web UI on :3000)
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    openFirewall = true;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://cloudflare-dns.com/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
      };
    };
  };

  # 2. Caddy Reverse Proxy (clean virtual-host URLs across LAN / Tailscale)
  services.caddy = {
    enable = true;
    virtualHosts = {
      "http://homelab, http://homelab.internal, :80".extraConfig = ''
        reverse_proxy 127.0.0.1:8082
      '';
      "http://adguard.homelab, http://adguard.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
      "http://vault.homelab, http://vault.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:8222
      '';
      "http://sync.homelab, http://sync.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:8384
      '';
      "http://status.homelab, http://status.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:3001
      '';
      "http://metrics.homelab, http://metrics.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:61208
      '';
      "http://drop.homelab, http://drop.homelab.internal".extraConfig = ''
        reverse_proxy 127.0.0.1:3002
      '';
    };
  };

  # 3. Homepage Dashboard (:8082, served on :80 by Caddy)
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "*";
    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];
    services = [
      {
        "Network & Security" = [
          {
            "AdGuard Home" = {
              href = "http://adguard.homelab.internal";
              description = "Network DNS & Ad Blocker (:3000)";
            };
          }
          {
            "Vaultwarden" = {
              href = "http://vault.homelab.internal";
              description = "Bitwarden Password Server (:8222)";
            };
          }
        ];
      }
      {
        "Sync & File Sharing" = [
          {
            "Syncthing" = {
              href = "http://sync.homelab.internal";
              description = "P2P Folder Sync across Mac, PC & Homelab (:8384)";
            };
          }
          {
            "PairDrop" = {
              href = "http://drop.homelab.internal";
              description = "Local & Tailscale File Drop (:3002)";
            };
          }
        ];
      }
      {
        "Monitoring & Metrics" = [
          {
            "Uptime Kuma" = {
              href = "http://status.homelab.internal";
              description = "Service Uptime & Alerts (:3001)";
            };
          }
          {
            "Glances" = {
              href = "http://metrics.homelab.internal";
              description = "System & Container Telemetry (:61208)";
            };
          }
        ];
      }
    ];
  };

  # 4. Vaultwarden (Bitwarden Server on 127.0.0.1:8222)
  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";
    config = {
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
    };
  };

  # 5. Syncthing (P2P File Sync on 127.0.0.1:8384 + sync ports 22000/21027)
  services.syncthing = {
    enable = true;
    user = user;
    dataDir = "/home/${user}/Sync";
    configDir = "/home/${user}/.config/syncthing";
    guiAddress = "127.0.0.1:8384";
    openDefaultPorts = true;
  };

  # 6. Uptime Kuma (Service Monitoring on 127.0.0.1:3001)
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";
      PORT = "3001";
    };
  };

  # 7. Glances (System & Container Web Telemetry on 127.0.0.1:61208)
  services.glances = {
    enable = true;
    port = 61208;
    extraArgs = [ "--webserver" ];
  };

  # 8. Docker & PairDrop OCI Container (127.0.0.1:3002 -> :3000)
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.pairdrop = {
      image = "lscr.io/linuxserver/pairdrop:latest";
      autoStart = true;
      ports = [ "127.0.0.1:3002:3000" ];
    };
  };

  # 9. Restic Automated Encrypted Backups (active once nixos/secrets.yaml is provisioned)
  services.restic.backups = lib.mkIf (builtins.pathExists ./secrets.yaml) {
    homelab = {
      initialize = true;
      repositoryFile = config.sops.secrets.restic_repo.path;
      passwordFile = config.sops.secrets.restic_password.path;
      paths = [
        "/var/lib/AdGuardHome"
        "/var/backup/vaultwarden"
        "/var/lib/uptime-kuma"
        "/home/${user}/Sync"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };

  # Decrypt nixos/secrets.yaml into /run/secrets/* in RAM when present
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = lib.mkIf (builtins.pathExists ./secrets.yaml) ./secrets.yaml;
  };

  environment.systemPackages = with pkgs; [
    age
    curl
    git
    htop
    neovim
    ripgrep
    sops
    ssh-to-age
    tailscale
  ];

  system.stateVersion = "25.05";
}
