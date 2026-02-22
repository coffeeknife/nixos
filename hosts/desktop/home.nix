{ config, pkgs, lib, hostname, ... }:

{
  imports = [
    ../../common/home.nix
    ./programs.nix
  ];

  home.file.".wallpaper" = {
    source = ../../wallpapers/rtrn.jpg;
    target = ".wallpaper";
  };

  dconf.settings = {
    "org/gnome/mutter" = {
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
  };
}
