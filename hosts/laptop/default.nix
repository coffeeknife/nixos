{ config, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.sensor.iio.enable = true;
  services.thermald.enable = true;

  # fingerprint scanner (138a:0097 needs python-validity + open-fprintd)
  services.python-validity.enable = true;
  services.open-fprintd.enable = true;

  # Auto-toggle WireGuard VPN based on WiFi SSID
  networking.networkmanager.dispatcherScripts = [{
    source = pkgs.writeText "vpn-toggle" ''
      #!/bin/bash
      IFACE="$1"
      ACTION="$2"

      case "$IFACE" in wg*|Home) exit 0 ;; esac

      # Do nothing if the VPN connection doesn't exist yet
      ${pkgs.networkmanager}/bin/nmcli -t -f NAME connection show | grep -qx "Home" || exit 0

      case "$ACTION" in
        up|connectivity-change)
          SSID=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
          if [ "$SSID" = "Everkeep" ]; then
            ${pkgs.networkmanager}/bin/nmcli connection down "Home" 2>/dev/null || true
          else
            ${pkgs.networkmanager}/bin/nmcli connection up "Home" 2>/dev/null || true
          fi
          ;;
      esac
    '';
    type = "basic";
  }];

  home-manager.users.robin = import ./home.nix;
}
