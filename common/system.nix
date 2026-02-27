{ config, pkgs, hostname, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "quiet" "splash" ];
  boot.plymouth = {
    enable = true;
    theme = "fade-in";
  };

  boot.kernelModules = [
    "usb_power_delivery"
    "usb_role"
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;        # Prefer zram over evicting file cache
    "vm.vfs_cache_pressure" = 50; # Keep filesystem caches longer
  };

  networking.hostName = hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [
    "en_GB.UTF-8/UTF-8"
  ];


  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Disable GNOME's SSH agent so Bitwarden's agent is used instead
  services.gnome.gcr-ssh-agent.enable = false;

  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  virtualisation.docker.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.robin = {
    isNormalUser = true;
    description = "Robin";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    initialPassword = "Eevee"; # that's my cat
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  # nix garbage collection
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";  # Run weekly
    options = "--delete-older-than 30d";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 128 * 1024 * 1024; # 128 MiB
  environment.systemPackages = with pkgs; [
    vim
    wget
    git

    xdg-desktop-portal
    xdg-desktop-portal-gnome
  ];

  environment.variables.EDITOR = "vim";
  system.stateVersion = "25.11"; # Did you read the comment?

}
