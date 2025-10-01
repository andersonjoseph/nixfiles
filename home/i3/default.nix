{
  config,
  pkgs,
  lib,
  nixosConfig,
  ...
}:
let
  mod = "Mod1";

  # Color Palette based on Kanagawa-Paper
  colors = {
    bg = "#1F1F28";
    fg = "#DCD7BA";
    gray = "#727169";
    red = "#C34043";
    green = "#76946A";
    yellow = "#DCA561";
    blue = "#658594";
    magenta = "#957FB8";
    cyan = "#6A9589";
    white = "#C8C093";
    dark_gray = "#2A2A37";
    light_blue = "#7E9CD8";
  };

  change-audio-port = pkgs.writeShellApplication {
    name = "change-audio-port";
    runtimeInputs = with pkgs; [
      bash
      pulseaudio
      jq
    ];
    text = ''
      #!${pkgs.bash}/bin/bash
      ${builtins.readFile ../../scripts/change-audio-port}
    '';
  };
in
{
  imports = [ ./bar ];
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      modifier = "${mod}";

      gaps = {
        inner = 6;
        outer = 3;
      };

      fonts = {
        names = [ "Iosevka Nerd Font Mono" ];
        size = 10.0;
      };

      keybindings = {
        "${mod}+p" =
          "exec ${pkgs.dmenu}/bin/dmenu_run -fn 'Iosevka Nerd Font Mono' -p 'Run:' -nb '${colors.bg}' -nf '${colors.fg}' -sb '${colors.blue}' -sf '${colors.bg}'";

        "${mod}+f" = "fullscreen toggle";
        "${mod}+Shift+f" = "exec --no-startup-id thunar";
        "floating_modifier" = "${mod}";
        "${mod}+Return" = "exec ${pkgs.alacritty}/bin/alacritty";

        "Print" = "exec --no-startup-id ${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png";
        "${mod}+grave" =
          "exec --no-startup-id ${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png";

        "${mod}+q" = "kill";
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";

        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        "${mod}+minus" = "scratchpad show";

        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";
        "${mod}+Shift+minus" = "move scratchpad";

        "${mod}+Shift+r" = "restart";
        "${mod}+r" = "mode resize";

        "${mod}+period" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "${mod}+comma" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";

        "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
        "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
        "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute   @DEFAULT_SINK@ toggle";

        "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +10%";
        "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 10%-";
      };

      keycodebindings = {
        "94" = "exec --no-startup-id ${change-audio-port}/bin/change-audio-port";
      };

      modes = {
        resize = {
          "h" = "resize shrink width 10 px or 10 ppt";
          "j" = "resize grow height 10 px or 10 ppt";
          "k" = "resize shrink height 10 px or 10 ppt";
          "l" = "resize grow width 10 px or 10 ppt";
          "Return" = "mode default";
          "Escape" = "mode default";
          "r" = "mode default";
        };
      };

      bars = [
        {
          position = "top";
          statusCommand = "i3blocks";
          trayOutput = "primary";
          fonts = {
            names = [ "Iosevka Nerd Font Mono" ];
            size = 10.0;
          };
          colors = {
            background = colors.bg;
            statusline = colors.fg;
            separator = colors.dark_gray;

            focusedWorkspace = {
              border = colors.blue;
              background = colors.blue;
              text = colors.bg;
            };

            activeWorkspace = {
              border = colors.dark_gray;
              background = colors.dark_gray;
              text = colors.fg;
            };

            inactiveWorkspace = {
              border = colors.bg;
              background = colors.bg;
              text = colors.gray;
            };

            urgentWorkspace = {
              border = colors.red;
              background = colors.red;
              text = colors.bg;
            };
          };
        }
      ];

      colors = {
        focused = {
          border = colors.blue;
          background = colors.blue;
          text = colors.bg;
          indicator = colors.blue;
          childBorder = colors.blue;
        };

        focusedInactive = {
          border = colors.dark_gray;
          background = colors.bg;
          text = colors.fg;
          indicator = colors.dark_gray;
          childBorder = colors.dark_gray;
        };

        unfocused = {
          border = colors.dark_gray;
          background = colors.bg;
          text = colors.gray;
          indicator = colors.dark_gray;
          childBorder = colors.dark_gray;
        };

        urgent = {
          border = colors.red;
          background = colors.red;
          text = colors.bg;
          indicator = colors.red;
          childBorder = colors.red;
        };

        placeholder = {
          border = colors.dark_gray;
          background = colors.bg;
          text = colors.gray;
          indicator = colors.dark_gray;
          childBorder = colors.dark_gray;
        };
      };

      startup = [
        {
          command = "i3-auto-layout";
          always = true;
        }
        {
          command = "nm-applet";
          always = true;
        }
        {
          command = "picom";
          always = true;
        }
        {
          command = "lxpolkit";
          always = true;
        }
        {
          command = "feh --bg-fill ${config.home.homeDirectory}/pictures/wallpaper";
          always = true;
        }
      ]
      ++ (lib.optionals (nixosConfig.custom.xrandr.startupCommand != null) [
        { command = nixosConfig.custom.xrandr.startupCommand; }
      ]);
    };

    extraConfig = ''
      for_window [class="^.*"] border pixel 0
    '';
  };
}
