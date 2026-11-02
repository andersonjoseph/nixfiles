{ ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.anderson =
      {
        pkgs,
        lib,
        nixosConfig,
        config,
        ...
      }:
      let
        isDesktopMachine = builtins.elem nixosConfig.networking.hostName (import ./desktop-hosts.nix);
      in
      {
        imports = [
          ./herdr.nix
          ./url-open.nix
          ./sideshow.nix
          ./t3.nix
        ]
        ++ (lib.optionals isDesktopMachine [
          ./i3
          ./alacritty.nix
          ./ghostty.nix
          ./hex.nix
        ]);

        home.stateVersion = "25.05";

        home.username = "anderson";
        home.homeDirectory = "/home/anderson";

        home.packages =
          with pkgs;
          [
            neovim
            hunk
            jailed-pi
            jq
            ripgrep
            tree
            fzf
            killall
            unzip
            lsof
            bc
          ]
          ++ (lib.optionals isDesktopMachine [
            vivaldi
            google-chrome
            keepassxc
            vlc
            qbittorrent
            jamesdsp
            xarchiver
            darktable
            slack
            thunderbird

            thunar
            thunar-volman
            thunar-archive-plugin
            xfconf

            autotiling
            sysstat
            networkmanagerapplet
            dunst
            pavucontrol
            lxsession

            maim
            feh
            alsa-utils
            xclip
            rofi
            (ffmpeg-full.override { withUnfree = true; })
            brightnessctl
            eternal-terminal
          ])
          ++ (lib.optionals nixosConfig.custom.isGaming [
            (heroic.override {
              extraPkgs = pkgs': [ pkgs'.gamemode ];
            })
          ]);

        services.redshift = lib.mkIf isDesktopMachine {
          enable = true;
          dawnTime = "7:00";
          duskTime = "16:35";
          temperature = {
            day = 6500;
            night = 3500;
          };
        };

        # delta stays installed for the lazygit pager; git itself pages through hunk.
        programs.delta.enable = true;

        programs.obs-studio = lib.mkIf isDesktopMachine {
          enable = true;
          package = (
            pkgs.obs-studio.override {
              cudaSupport = true;
            }
          );
        };

        programs.git = {
          enable = true;
          settings = {
            core.pager = "hunk pager";
            user = {
              name = "anderson";
              email = "andersonjoseph@mailfence.com";
            };
          };
          signing = {
            signByDefault = true;
            format = "ssh";
          };
        };

        programs.lazygit = {
          enable = true;
          settings = {
            git.pagers = [
              {
                pager = "delta --dark --paging=never";
                colorArg = "always";
              }
            ];
          };
        };

        programs.lazydocker = {
          enable = true;
        };

        programs.bash = {
          enable = true;
          enableCompletion = true;
          shellAliases = {
            cl = "clear";
            wtf = "sudo $(fc -ln -1)";
          };
          initExtra = ''
            eval "$(fzf --bash)"
          '';
          bashrcExtra = ''
            export MANPAGER='nvim +Man!'
            export PATH="$PATH:$HOME/go/bin"
          '';
        };

        programs.direnv = {
          enable = true;
          enableBashIntegration = true;
          nix-direnv.enable = true;
        };

        programs.starship = {
          enable = true;
          settings = pkgs.lib.importTOML ./starship.toml;
        };

        # Entries link straight into the checkout so edits apply without a
        # rebuild. Ssh needs a user-owned config: sandboxes without a root
        # mapping (T3 AppImage, agent jails) show store files as nobody. The
        # agent state dirs hold live data; only named entries are managed and
        # a colliding real file moves to *.backup once. The wallpaper is the
        # one store-sourced entry.
        home.file =
          let
            repo = "${config.home.homeDirectory}/configuration/home";
            link = rel: {
              source = config.lib.file.mkOutOfStoreSymlink "${repo}/${rel}";
            };
            linkDir =
              target: rel:
              lib.mapAttrs' (name: _type: lib.nameValuePair "${target}/${name}" (link "${rel}/${name}")) (
                builtins.readDir (./. + "/${rel}")
              );
          in
          {
            ".pi/agent/AGENTS.md" = link "pi/AGENTS.md";
            ".claude/CLAUDE.md" = link "claude/CLAUDE.md";
            ".ssh/config" = link "ssh/config";
            ".config/nvim" = link "nvim";
          }
          // linkDir ".pi/agent/skills" "skills"
          // linkDir ".claude/skills" "skills"
          // lib.optionalAttrs (nixosConfig.custom.wallpaperFile != null) {
            "pictures/wallpaper".source = nixosConfig.custom.wallpaperFile;
          };

      };
  };
}
