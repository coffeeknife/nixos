{ config, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  home-manager.users.robin = import ./home.nix;
}
