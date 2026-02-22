{ config, pkgs, lib, hostname, ... }:

{
  imports = [
    ../../common/home.nix
    ./programs.nix
  ];

  home.file.".wallpaper" = {
    source = ../../wallpapers/aventurine.jpeg;
    target = ".wallpaper";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      show-battery-percentage = true;
    };
  };
}
