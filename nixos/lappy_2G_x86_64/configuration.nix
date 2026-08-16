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

  users.users = {
    dbg = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
    };
    hass.extraGroups = [ "dialout" ];
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
    extraComponents = [
      "esphome"
      "met"
      "radio_browser"
      "isal"
      "usb"
      "zha"
    ];
    customComponents = [
      pkgs.home-assistant-custom-components.adaptive_lighting
    ];
    extraPackages = py: with py; [
      psycopg2
      go2rtc-client
      gtts
    ];

    config = {
      recorder.db_url = "postgresql://@/hass";
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
      adaptive_lighting = [
        {
          name = "adapt-flux";
          lights = [
            "light.sengled_e11_n1ea_light"
            "light.sengled_e11_n1ea_e6ab0600_level_light_color_on_off"
            "light.sengled_e11_n1ea_4c490300_level_light_color_on_off"
            "light.osram_lightify_a19_rgbw_84a60700_level_light_color_on_off"
          ];
          prefer_rgb_color = false;
          interval = 150;
          min_color_temp = 1000;
          sleep_brightness = 1;
          sleep_rgb_or_color_temp = "rgb_color";
          sleep_rgb_color = [ 255 0 0 ];
          min_sunset_time = "18:00:00";
        }
      ];
    };
  };

  systemd = {
    tmpfiles.rules = [ # create files if they do not exist
      "f ${config.services.home-assistant.configDir}/automations.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scenes.yaml 0644 hass hass"
      "f ${config.services.home-assistant.configDir}/scripts.yaml 0644 hass hass"
    ];
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

