{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
        user.name = "coffeeknife";
        user.email = "coffeeknife@proton.me";
        gpg = {
            format = "ssh";
        };
        pull.rebase = true;
        init.defaultBranch = "main";
    };
    signing = {
        signByDefault = true;
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIe2PZOs/3wRmVtkvYpuihuk+ywyoD+l82LbCKrqvX4p";
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        catppuccin.catppuccin-vsc
        anthropic.claude-code
        jnoortheen.nix-ide
        file-icons.file-icons
        tamasfe.even-better-toml
      ];
      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', monospace";
        "editor.fontSize" = 14;
        "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.iconTheme" = "file-icons";
        "git.confirmSync" = false;
        "git.autofetch" = true;
        "git.autoStash" = true;
        "git.enableSmartCommit" = true;
        "claudeCode.preferredLocation" = "panel";
      };
    };
  };

  programs.brave = {
    enable = true;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
      { id = "dhdgffkkebhmkfjojejmpbldmpobfkfo"; } # TamperMonkey
    ];
    commandLineArgs = [
      "--disable-features=PasswordManager,Autofill"
    ];
  };

  programs.vesktop = {
    enable = true;
    settings = {
      tray = true;
      minimizeToTray = true;
      arRPC = true;
      hardwareAcceleration = true;
      customTitleBar = true;
      autoStartMinimized = true;
    };
    vencord.settings = {
      notifyAboutUpdates = false;
      plugins = {
        FakeNitro.enabled = true;
      };
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../config/starship.toml);
  };

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      eval "$(starship init bash)"
    '';
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "kube-1".hostname = "192.168.200.2";
      "kube-2".hostname = "192.168.200.3";
      "kube-3".hostname = "192.168.200.4";
      "etheirys" = {
        hostname = "192.168.1.53";
        user = "root";
      };
      "gallifrey".hostname = "192.168.1.54";
      "vulcan".hostname = "192.168.1.69";
    };
  };

}
