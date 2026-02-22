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

  home-manager.users.robin = import ./home.nix;
}
