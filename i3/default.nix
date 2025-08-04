{ config, pkgs, lib, ... }:
let 
  mod = "Mod1";
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
	names = [ "Terminess Nerd Font Mono" ];
	size  = 10.0;
      };

      keybindings = {
	"${mod}+p" = "exec ${pkgs.dmenu}/bin/dmenu_run -fn 'Terminess Nerd Font Mono' -p 'Run:' -nb '#0A0A0A' -nf '#DEEEED' -sb '#7788AA' -sf '#DEEEED'";

	"${mod}+f"           = "fullscreen toggle";
	"${mod}+Shift+f"     = "exec --no-startup-id thunar";
	"floating_modifier" = "${mod}";
	"${mod}+Return"      = "exec ${pkgs.alacritty}/bin/alacritty";

	"Print" = "exec --no-startup-id ${pkgs.maim}/bin/maim -s | xclip -selection clipboard -t image/png";

	"${mod}+q"           = "kill";
	"${mod}+h"           = "focus left";
	"${mod}+j"           = "focus down";
	"${mod}+k"           = "focus up";
	"${mod}+l"           = "focus right";
	"${mod}+Shift+h"     = "move left";
	"${mod}+Shift+j"     = "move down";
	"${mod}+Shift+k"     = "move up";
	"${mod}+Shift+l"     = "move right";
	"${mod}+Shift+space" = "floating toggle";
	"${mod}+space"       = "focus mode_toggle";

	"${mod}+1"           = "workspace number 1";
	"${mod}+2"           = "workspace number 2";
	"${mod}+3"           = "workspace number 3";
	"${mod}+4"           = "workspace number 4";
	"${mod}+5"           = "workspace number 5";
	"${mod}+6"           = "workspace number 6";
	"${mod}+7"           = "workspace number 7";
	"${mod}+8"           = "workspace number 8";
	"${mod}+9"           = "workspace number 9";
	"${mod}+0"           = "workspace number 10";

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

	"${mod}+Shift+r" = "restart";
	"${mod}+r"       = "mode resize";

	"XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +10%";
	"XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -10%";
	"XF86AudioMute"        = "exec --no-startup-id pactl set-sink-mute   @DEFAULT_SINK@ toggle";
	"XF86AudioMicMute"     = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle";

	"XF86MonBrightnessUp"   = "exec --no-startup-id brightnessctl set +10%";
	"XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 10%-";
      };

      modes = {
	resize = {
	  "h"      = "resize shrink width 10 px or 10 ppt";
	  "j"      = "resize grow height 10 px or 10 ppt";
	  "k"      = "resize shrink height 10 px or 10 ppt";
	  "l"      = "resize grow width 10 px or 10 ppt";
	  "Return" = "mode default";
	  "Escape" = "mode default";
	  "r"      = "mode default";
	};
      };

      bars = [{
	position = "top";
	statusCommand = "i3blocks";
	trayOutput = "primary";
	fonts = {
	  names = [ "Terminess Nerd Font Mono" ];
	  size  = 10.0;
	};
	colors = {
	  background      = "#1F1F28";
	  statusline      = "#7E9CD8";
	  separator       = "#7E9CD8";

	  focusedWorkspace = {
	    border     = "#7E9CD8";
	    background = "#6A9589";
	    text       = "#1F1F28";
	  };

	  activeWorkspace = {
	    border     = "#7E9CD8";
	    background = "#1F1F28";
	    text       = "#1F1F28";
	  };

	  inactiveWorkspace = {
	    border     = "#7E9CD8";
	    background = "#1F1F28";
	    text       = "#7E9CD8";
	  };

	  urgentWorkspace = {
	    border     = "#7E9CD8";
	    background = "#DCD7BA";
	    text       = "#7E9CD8";
	  };
	};
      }];
    };

    extraConfig = ''
      for_window [class="^.*"] border pixel 0
      exec --no-startup-id nm-applet
      exec_always --no-startup-id i3-auto-layout
      exec_always feh --bg-fill ${config.home.homeDirectory}/pictures/wallpaper
    '';
  };
}
