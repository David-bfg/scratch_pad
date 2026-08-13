# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./pass+keys.nix
    ];

  ############################################################
  # Boot
  ############################################################

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "btrfs" ];

  ############################################################
  # Filesystem maintenance
  ############################################################

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  services.btrfs.autoScrub.fileSystems = [ "/" ];

  ############################################################
  # Stay powered
  ############################################################
  
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  ############################################################
  # Networking
  ############################################################

  networking = {
    hostName = "naster-node"; # Define your hostname.
    hostId = "32B1EDBD";
    wireless.enable = true;
  };

  time.timeZone = "America/Chicago";

  ############################################################
  # Users
  ############################################################

  users.users.dbg = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
  };

  ############################################################
  # Packages
  ############################################################

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    htop
    vim
    wget
    git
    tmux
  ];

  ############################################################
  # SSH
  ############################################################

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "dbg" ];
    };
  };

  ############################################################
  # Headless operation
  ############################################################

  services.xserver.enable = false;

  ############################################################
  # HomeAssistant
  ############################################################
  
  services.home-assistant = {
    enable = true;
    # configDir = "/home/dbg/services/home-assistant";
    package = (pkgs.home-assistant.override {
      extraPackages = py: with py; [ psycopg2 ];
    }).overrideAttrs (oldAttrs: {
      doInstallCheck = false;
    });
    config.recorder.db_url = "postgresql://@/hass";
  };

  ############################################################
  # PostgreSQL
  ############################################################

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };

  ############################################################
  # AdGuard Home (DNS)
  ############################################################

  services.adguardhome = {
    enable = true;

    settings = {
      http = {
        address = "0.0.0.0:3000";
      };
    };
  };

  ############################################################
  # FireWall
  ############################################################

  networking.firewall.allowedTCPPorts = [
    22    # SSH
    53    # DNS
    80    # HTTP
    8123  # Home Assistant
    3000  # AdGuard Home
  ];

  networking.firewall.allowedUDPPorts = [
    53
  ];

  ############################################################
  # Nix
  ############################################################

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  ############################################################
  # State version
  ############################################################

  system.stateVersion = "26.05";

}

