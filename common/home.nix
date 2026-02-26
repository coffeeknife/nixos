{ config, pkgs, lib, hostname, ... }:
let
  borgRepo = "ssh://robin@vulcan/mnt/birdpool/backup/devices/${hostname}";
  borgKeyFile = "${config.home.homeDirectory}/.ssh/borg_ed25519";
  borgKeyringAttr = "borg-passphrase-${hostname}";
  secretTool = "${pkgs.libsecret}/bin/secret-tool";
in
{
  imports = [
    ./programs.nix
  ];

  home.username = "robin";
  home.homeDirectory = "/home/robin";

  home.file.".face" = {
    source = ../ratio.jpg;
    target = ".face";
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  };

  systemd.user.sessionVariables = {
    SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";
  };

  home.packages = with pkgs; [
    # utilities
    fastfetch
    kubectl
    kubernetes-helm
    fluxcd
    jq
    usbutils
    pciutils
    go

    # apps
    (appimageTools.wrapType2 rec {
      name = "BambuStudio";
      pname = "bambu-studio";
      version = "02.04.00.70";
      ubuntu_version = "24.04_PR-8834";

      src = pkgs.fetchurl {
        url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
        sha256 = "sha256:26bc07dccb04df2e462b1e03a3766509201c46e27312a15844f6f5d7fdf1debd";
      };

      profile = ''
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
      '';

      extraPkgs = pkgs: with pkgs; [
        cacert
        glib
        glib-networking
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        webkitgtk_4_1
      ];

      extraInstallCommands = let
        appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
      in ''
        install -m 444 -D ${appimageContents}/BambuStudio.desktop $out/share/applications/BambuStudio.desktop
        install -m 444 -D ${appimageContents}/BambuStudio.png $out/share/icons/hicolor/192x192/apps/BambuStudio.png
        substituteInPlace $out/share/applications/BambuStudio.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=bambu-studio'
      '';
    })
    (appimageTools.wrapType2 rec {
      name = "Cider";
      pname = "cider";
      version = "3.1.8";

      src = pkgs.requireFile {
        name = "cider-v3.1.8-linux-x64.AppImage";
        sha256 = "b3508c6007c350b684c8ed23660b80d9b03b0fba20a91478bff2e4303fa5b8ac"; # replace with real hash
        message = ''
          Cider 2 must be downloaded manually from itch.io.
          Download it from https://https://taproom.cider.sh/dashboard
          Then add it to the Nix store:
            nix-store --add-fixed sha256 /path/to/Cider-linux-x64.AppImage
        '';
      };

      extraInstallCommands = let
        appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
      in ''
        install -m 444 -D ${appimageContents}/Cider.png $out/share/icons/hicolor/256x256/apps/cider.png
      '';
    })
    orca-slicer

    element-desktop
    claude-code
    bitwarden-desktop
    (protonmail-desktop.overrideAttrs (oldAttrs: {
      postFixup = (oldAttrs.postFixup or "") + ''
        wrapProgram $out/bin/proton-mail \
          --add-flags "--ozone-platform=x11"
      '';
      postInstall = (oldAttrs.postInstall or "") + ''
        install -m 444 -D $out/share/pixmaps/proton-mail.png $out/share/icons/hicolor/scalable/apps/proton-mail.svg
      '';
    }))
    nextcloud-client
    jetbrains.pycharm
    libreoffice
    borgbackup
    libsecret
    (pkgs.writeShellScriptBin "borg-last-backup" ''
      export BORG_REPO="${borgRepo}"
      export BORG_RSH="${pkgs.openssh}/bin/ssh -i ${borgKeyFile}"
      export BORG_PASSCOMMAND="${secretTool} lookup application borg key ${borgKeyringAttr}"
      ${pkgs.borgbackup}/bin/borg list --last 1 --format '{time}' 2>/dev/null
    '')
    (pkgs.writeShellScriptBin "borg-browse" ''
      set -euo pipefail
      export BORG_REPO="${borgRepo}"
      export BORG_RSH="${pkgs.openssh}/bin/ssh -i ${borgKeyFile}"
      export BORG_PASSCOMMAND="${secretTool} lookup application borg key ${borgKeyringAttr}"

      MOUNT_DIR="''${XDG_RUNTIME_DIR:-/tmp}/borg-mount"
      mkdir -p "$MOUNT_DIR"

      if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
        ${pkgs.xdg-utils}/bin/xdg-open "$MOUNT_DIR"
        exit 0
      fi

      if [ "''${1:-}" = "--latest" ]; then
        ARCHIVE=$(${pkgs.borgbackup}/bin/borg list --last 1 --format '{archive}' 2>/dev/null)
        ${pkgs.borgbackup}/bin/borg mount "::$ARCHIVE" "$MOUNT_DIR"
      else
        ${pkgs.borgbackup}/bin/borg mount :: "$MOUNT_DIR"
      fi

      ${pkgs.xdg-utils}/bin/xdg-open "$MOUNT_DIR"
      echo "Backups mounted at $MOUNT_DIR"
      echo "Run 'borg-umount' to unmount when done."
    '')
    (pkgs.writeShellScriptBin "borg-umount" ''
      MOUNT_DIR="''${XDG_RUNTIME_DIR:-/tmp}/borg-mount"
      if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
        ${pkgs.coreutils}/bin/fusermount -u "$MOUNT_DIR"
        echo "Unmounted borg backups."
      else
        echo "Nothing mounted at $MOUNT_DIR"
      fi
    '')

    # gnome
    fairywren
    gnome-tweaks
    gnome-catppuccin
    gnome-remote-desktop
    gnomeExtensions.blur-my-shell
    gnomeExtensions.gsconnect
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.user-themes
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.edit-desktop-files
    (gnomeExtensions.runcat.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        substituteInPlace $out/share/gnome-shell/extensions/runcat@kolesnikov.se/extension.js \
          --replace-fail "MainPanel.addToStatusArea('runcat-indicator', this.#indicator)" \
                         "MainPanel.addToStatusArea('runcat-indicator', this.#indicator, -1, 'left')"
      '';
    }))
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "gnome-shell-extension-claude-code-usage";
      version = "3";
      src = pkgs.fetchFromGitHub {
        owner = "Haletran";
        repo = "claude-usage-extension";
        rev = "b51d7e8fd837c1fc6615109165d455b396006853";
        hash = "sha256-KhfIsewrR9MXBGpVvk7HSFVFXSmW+I4jUdCxZ5WccYg=";
      };
      nativeBuildInputs = [ pkgs.glib ];
      installPhase = ''
        mkdir -p $out/share/gnome-shell/extensions/claude-code-usage@haletran.com
        cp -r . $out/share/gnome-shell/extensions/claude-code-usage@haletran.com/
        glib-compile-schemas $out/share/gnome-shell/extensions/claude-code-usage@haletran.com/schemas/
      '';
      meta.license = lib.licenses.gpl3;
    })
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "gnome-shell-extension-borg-backup-status";
      version = "1";
      src = ../extensions/borg-backup-status;
      uuid = "borg-backup-status@coffeeknife";
      dontUnpack = true;
      installPhase = let
        uuid = "borg-backup-status@coffeeknife";
      in ''
        dir=$out/share/gnome-shell/extensions/${uuid}
        mkdir -p $dir
        cp $src/borg-extension.js $dir/extension.js
        echo '${builtins.toJSON {
          name = "Borg Backup Status";
          description = "Shows borg backup status in the top bar";
          inherit uuid;
          shell-version = [ "45" "46" "47" "48" "49" ];
          version = 1;
        }}' > $dir/metadata.json
      '';
    })

    # fonts
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-cove
    noto-fonts-cjk-sans
  ];

  xdg.desktopEntries = {
    OrcaSlicer = {
      name = "OrcaSlicer";
      genericName = "3D Printing Software";
      icon = "${pkgs.orca-slicer}/share/icons/hicolor/192x192/apps/OrcaSlicer.png";
      exec = "orca-slicer %U";
      terminal = false;
      categories = [ "Graphics" "3DGraphics" "Engineering" ];
      mimeType = [ "model/stl" "model/3mf" "application/vnd.ms-3mfdocument" "application/prs.wavefront-obj" "application/x-amf" "x-scheme-handler/orcaslicer" ];
      startupNotify = false;
      settings.StartupWMClass = "orca-slicer";
    };
    borg-browse = {
      name = "Browse Backups";
      comment = "Mount and browse borg backup archives";
      icon = "drive-harddisk";
      exec = "borg-browse";
      terminal = false;
      categories = [ "Utility" ];
    };
    borg-browse-latest = {
      name = "Browse Latest Backup";
      comment = "Mount and browse the most recent borg archive";
      icon = "drive-harddisk";
      exec = "borg-browse --latest";
      terminal = false;
      categories = [ "Utility" ];
    };
    borg-umount = {
      name = "Unmount Backups";
      comment = "Unmount borg backup archives";
      icon = "media-eject";
      exec = "borg-umount";
      terminal = false;
      categories = [ "Utility" ];
    };
    cider = {
      name = "Cider";
      genericName = "Music Player";
      icon = "cider";
      exec = "cider";
      terminal = false;
      categories = [ "Audio" "Music" "Player" "AudioVideo" ];
      comment = "Apple Music client";
      settings.StartupWMClass = "cider";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
    };
  };

  xdg.autostart = {
    readOnly = true;
    entries = [
      "${pkgs.nextcloud-client}/share/applications/nextcloud-client.desktop"
      "${pkgs.bitwarden-desktop}/share/applications/bitwarden-desktop.desktop"
    ];
  };

  xdg.configFile."autostart/vesktop.desktop".source =
    "${pkgs.vesktop}/share/applications/vesktop.desktop";

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-blue-compact";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        size = "compact";
      };
    };
    iconTheme = {
      name = "FairyWren_Dark";
      package = pkgs.fairywren;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          dash-to-dock.extensionUuid
          appindicator.extensionUuid
          user-themes.extensionUuid
          desktop-icons-ng-ding.extensionUuid
          edit-desktop-files.extensionUuid
          runcat.extensionUuid
          gsconnect.extensionUuid
          "claude-code-usage@haletran.com"
          "borg-backup-status@coffeeknife"
        ];
        favorite-apps = [
          "org.gnome.Settings.desktop"
          "org.gnome.Nautilus.desktop"
          "brave-browser.desktop"
          "org.gnome.Calendar.desktop"
          "proton-mail.desktop"
          "vesktop.desktop"
          "element-desktop.desktop"
          "org.gnome.Console.desktop"
          "codium.desktop"
          "cider.desktop"
          "BambuStudio.desktop"
          "OrcaSlicer.desktop"
        ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        clock-format = "12h";
        clock-show-weekday = true;
      };
      "org/gnome/Console" = {
        use-system-font = false;
        custom-font = "JetBrainsMono Nerd Font 12";
      };
      "org/gnome/desktop/background" = {
        picture-uri-dark = "file:///home/robin/.wallpaper";
        color-shading-type = "solid";
        picture-options = "zoom";
      };
      "org/gnome/shell/extensions/user-theme" = {
        name = "Gnome-catppuccin";
      };
    };
  };

  home.file.".config/Brave Software/Policies/managed/policies.json".text = ''
  {
    "BraveRewardsDisabled": true,
    "BraveWalletDisabled": true,
    "LeoAssistantDisabled": true
  }
  '';

  # Borg backup to vulcan over SSH
  home.activation.borgbackup-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${borgKeyFile}" ]; then
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "${borgKeyFile}" -N "" -C "borg-backup"
      echo "NOTE: Copy ${borgKeyFile}.pub to vulcan with: ssh-copy-id -i ${borgKeyFile}.pub robin@vulcan"
    fi
    EXISTING=$(${secretTool} lookup application borg key ${borgKeyringAttr} 2>/dev/null || true)
    if [ -z "$EXISTING" ]; then
      PASSPHRASE=$(${pkgs.openssl}/bin/openssl rand -base64 32)
      echo "$PASSPHRASE" | ${secretTool} store --label="Borg backup passphrase (${hostname})" application borg key ${borgKeyringAttr}
      echo "NOTE: Borg passphrase generated and stored in GNOME Keyring"
      echo "NOTE: Save it to Bitwarden as a secure note for disaster recovery"
    fi
  '';

  systemd.user.services.borgbackup-home = {
    Unit.Description = "Borg backup home directory to vulcan";
    Service = {
      Type = "oneshot";
      ExecStart = toString (pkgs.writeShellScript "borg-backup-home" ''
        set -euo pipefail
        export BORG_REPO="${borgRepo}"
        export BORG_RSH="${pkgs.openssh}/bin/ssh -i ${borgKeyFile}"
        export BORG_PASSCOMMAND="${secretTool} lookup application borg key ${borgKeyringAttr}"

        # initialise repo on first run
        ${pkgs.borgbackup}/bin/borg info > /dev/null 2>&1 || \
          ${pkgs.borgbackup}/bin/borg init --encryption=repokey

        ${pkgs.borgbackup}/bin/borg create \
          --compression auto,zstd \
          --exclude "sh:${config.home.homeDirectory}/.*" \
          --exclude "${config.home.homeDirectory}/Nextcloud" \
          "::${hostname}-{now}" \
          ${config.home.homeDirectory}

        ${pkgs.borgbackup}/bin/borg prune \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6

        ${pkgs.borgbackup}/bin/borg compact
      '');
    };
  };

  systemd.user.timers.borgbackup-home = {
    Unit.Description = "Daily borg backup";
    Timer = {
      OnUnitActiveSec = "24h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;
}
