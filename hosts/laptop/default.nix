{ config, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.sensor.iio.enable = true;

  # Intel 8265 WiFi+BT share one antenna — performance power scheme reduces
  # contention and fixes Bluetooth audio dropouts
  boot.extraModprobeConfig = ''
    options iwlmvm power_scheme=1
  '';
  services.thermald.enable = true;

  # Compressed in-memory swap — prevents freezes when RAM fills up
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # fingerprint scanner (138a:0097 needs python-validity + open-fprintd)
  services.python-validity.enable = true;
  services.open-fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = true;

  # Auto-toggle WireGuard VPN based on WiFi SSID
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeShellScript "vpn-toggle" ''
      IFACE="$1"
      ACTION="$2"

      # Only act on wifi interfaces
      case "$IFACE" in wl*) ;; *) exit 0 ;; esac

      # Do nothing if the VPN connection doesn't exist yet
      ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | grep -qx "Home" || exit 0

      case "$ACTION" in
        up)
          SSID=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
          if [ "$SSID" = "Everkeep" ]; then
            ${pkgs.networkmanager}/bin/nmcli connection down "Home" 2>/dev/null &
          else
            ${pkgs.networkmanager}/bin/nmcli connection up "Home" 2>/dev/null &
          fi
          ;;
        down)
          ${pkgs.networkmanager}/bin/nmcli connection down "Home" 2>/dev/null &
          ;;
      esac
    '';
    type = "basic";
  }];

  home-manager.users.robin = import ./home.nix;
}
