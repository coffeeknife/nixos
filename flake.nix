{
  description = "NixOS flake — desktop & laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
    gnome-catppuccin = {
      url = "git+https://github.com/elisesouche/gnome-catppuccin?ref=refs/tags/v1.0&submodules=1";
      flake = false;
    };
    nixos-fingerprint-sensor = {
      url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor?ref=24.11";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, alacritty-theme, gnome-catppuccin, nixos-fingerprint-sensor, ... }@inputs:
  let
    pkgs-stable = import nixpkgs-stable { system = "x86_64-linux"; };

    overlays = [
      alacritty-theme.overlays.default
      (final: prev: {
        gnome-catppuccin = final.callPackage "${gnome-catppuccin}" {};
        python313Packages = prev.python313Packages.overrideScope (pyFinal: pyPrev: {
          picosvg = pyPrev.picosvg.overridePythonAttrs {
            doCheck = false;
          };
        });
      })
    ];

    mkHost = { hostname, hostDir, extraModules ? [] }: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit hostname; };
      modules = [
        ./common/system.nix
        hostDir
        home-manager.nixosModules.home-manager
        {
          home-manager.backupFileExtension = "old";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit hostname pkgs-stable; };
          nixpkgs.overlays = overlays;
        }
      ] ++ extraModules;
    };
  in {
    nixosConfigurations.robin-desktop = mkHost {
      hostname = "robin-desktop";
      hostDir = ./hosts/desktop;
    };

    nixosConfigurations.robin-laptop = mkHost {
      hostname = "robin-laptop";
      hostDir = ./hosts/laptop;
      extraModules = [
        nixos-fingerprint-sensor.nixosModules.python-validity
        nixos-fingerprint-sensor.nixosModules.open-fprintd
      ];
    };
  };

}
