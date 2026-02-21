{ ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "ansi";
      default_mode = "locked";
      show_startup_tips = false;
      web_server_ip = "0.0.0.0";
      plugins = {
        about.location = "zellij:about";
        compact-bar.location = "zellij:compact-bar";
        configuration.location = "zellij:configuration";
        filepicker = {
          location = "zellij:strider";
          cwd = "/";
        };
        plugin-manager.location = "zellij:plugin-manager";
        session-manager.location = "zellij:session-manager";
        status-bar.location = "zellij:status-bar";
        strider.location = "zellij:strider";
        tab-bar.location = "zellij:tab-bar";
        welcome-screen = {
          location = "zellij:session-manager";
          welcome_screen = true;
        };
      };
      web_client.font = "monospace";
    };
    extraConfig = ''
      keybinds clear-defaults=true {
          locked {
              bind "Ctrl f" { SwitchToMode "normal"; }
          }
          pane {
              bind "r" { SwitchToMode "renamepane"; PaneNameInput 0; }
              bind "j" { NewPane "down"; SwitchToMode "locked"; }
              bind "k" { NewPane "up"; SwitchToMode "locked"; }
              bind "l" { NewPane "right"; SwitchToMode "locked"; }
              bind "h" { NewPane "left"; SwitchToMode "locked"; }
              bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "locked"; }
              bind "i" { TogglePanePinned; SwitchToMode "locked"; }
              bind "n" { NewPane; SwitchToMode "locked"; }
              bind "p" { SwitchToMode "normal"; }
              bind "s" { NewPane "stacked"; SwitchToMode "locked"; }
              bind "f" { ToggleFloatingPanes; SwitchToMode "locked"; }
              bind "x" { CloseFocus; SwitchToMode "locked"; }
              bind "z" { TogglePaneFrames; SwitchToMode "locked"; }
          }
          tab {
              bind "left" { GoToPreviousTab; }
              bind "down" { GoToNextTab; }
              bind "up" { GoToPreviousTab; }
              bind "right" { GoToNextTab; }
              bind "1" { GoToTab 1; SwitchToMode "locked"; }
              bind "2" { GoToTab 2; SwitchToMode "locked"; }
              bind "3" { GoToTab 3; SwitchToMode "locked"; }
              bind "4" { GoToTab 4; SwitchToMode "locked"; }
              bind "5" { GoToTab 5; SwitchToMode "locked"; }
              bind "6" { GoToTab 6; SwitchToMode "locked"; }
              bind "7" { GoToTab 7; SwitchToMode "locked"; }
              bind "8" { GoToTab 8; SwitchToMode "locked"; }
              bind "9" { GoToTab 9; SwitchToMode "locked"; }
              bind "[" { BreakPaneLeft; SwitchToMode "locked"; }
              bind "]" { BreakPaneRight; SwitchToMode "locked"; }
              bind "b" { BreakPane; SwitchToMode "locked"; }
              bind "h" { GoToPreviousTab; }
              bind "j" { GoToNextTab; }
              bind "k" { GoToPreviousTab; }
              bind "l" { GoToNextTab; }
              bind "n" { NewTab; SwitchToMode "locked"; }
              bind "r" { SwitchToMode "renametab"; TabNameInput 0; }
              bind "s" { ToggleActiveSyncTab; SwitchToMode "locked"; }
              bind "t" { SwitchToMode "normal"; }
              bind "x" { CloseTab; SwitchToMode "locked"; }
              bind "tab" { ToggleTab; }
          }
          resize {
              bind "left" { Resize "Increase left"; }
              bind "down" { Resize "Increase down"; }
              bind "up" { Resize "Increase up"; }
              bind "right" { Resize "Increase right"; }
              bind "+" { Resize "Increase"; }
              bind "-" { Resize "Decrease"; }
              bind "=" { Resize "Increase"; }
              bind "H" { Resize "Decrease left"; }
              bind "J" { Resize "Decrease down"; }
              bind "K" { Resize "Decrease up"; }
              bind "L" { Resize "Decrease right"; }
              bind "h" { Resize "Increase left"; }
              bind "j" { Resize "Increase down"; }
              bind "k" { Resize "Increase up"; }
              bind "l" { Resize "Increase right"; }
              bind "r" { SwitchToMode "normal"; }
          }
          move {
              bind "left" { MovePane "left"; }
              bind "down" { MovePane "down"; }
              bind "up" { MovePane "up"; }
              bind "right" { MovePane "right"; }
              bind "h" { MovePane "left"; }
              bind "j" { MovePane "down"; }
              bind "k" { MovePane "up"; }
              bind "l" { MovePane "right"; }
              bind "m" { SwitchToMode "normal"; }
              bind "n" { MovePane; }
              bind "p" { MovePaneBackwards; }
              bind "tab" { MovePane; }
          }
          scroll {
              bind "e" { EditScrollback; SwitchToMode "locked"; }
              bind "s" { SwitchToMode "normal"; }
          }
          session {
              bind "c" {
                  LaunchOrFocusPlugin "configuration" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "locked"
              }
              bind "d" { Detach; }
              bind "o" { SwitchToMode "normal"; }
              bind "p" {
                  LaunchOrFocusPlugin "plugin-manager" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "locked"
              }
              bind "s" {
                  LaunchOrFocusPlugin "zellij:share" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "locked"
              }
              bind "w" {
                  LaunchOrFocusPlugin "session-manager" {
                      floating true
                      move_to_focused_tab true
                  }
                  SwitchToMode "locked"
              }
          }
          shared_among "normal" "locked" {
              bind "Alt up" {
                  MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                      name "move_focus"
                      payload "up"
                      move_mod "alt"
                      use_arrow_keys true
                  }
              }
              bind "Alt down" {
                  MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                      name "move_focus"
                      payload "down"
                      move_mod "alt"
                      use_arrow_keys true
                  }
              }
              bind "Alt right" {
                  MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                      name "move_focus_or_tab"
                      payload "right"
                      move_mod "alt"
                      use_arrow_keys true
                  }
              }
              bind "Alt left" {
                  MessagePlugin "https://github.com/hiasr/vim-zellij-navigator/releases/download/0.3.0/vim-zellij-navigator.wasm" {
                      name "move_focus_or_tab"
                      payload "left"
                      move_mod "alt"
                      use_arrow_keys true
                  }
              }
              bind "Ctrl Alt +" { Resize "Increase"; }
              bind "Ctrl Alt -" { Resize "Decrease"; }
              bind "Ctrl Alt =" { Resize "Increase"; }
              bind "Ctrl [" { PreviousSwapLayout; }
              bind "Ctrl ]" { NextSwapLayout; }
              bind "Ctrl Alt f" { ToggleFocusFullscreen; }
              bind "Ctrl Alt n" { NewPane; }
              bind "Ctrl Shift t" { NewTab; }
              bind "Ctrl Alt 1" { GoToTab 1; }
              bind "Ctrl Alt 2" { GoToTab 2; }
              bind "Ctrl Alt 3" { GoToTab 3; }
              bind "Ctrl Alt 4" { GoToTab 4; }
          }
          shared_except "locked" "renametab" "renamepane" {
              bind "Ctrl f" { SwitchToMode "locked"; }
              bind "Ctrl q" { Quit; }
          }
          shared_except "locked" "entersearch" {
              bind "enter" { SwitchToMode "locked"; }
          }
          shared_except "locked" "entersearch" "renametab" "renamepane" {
              bind "esc" { SwitchToMode "locked"; }
          }
          shared_except "locked" "entersearch" "renametab" "renamepane" "move" {
              bind "m" { SwitchToMode "move"; }
          }
          shared_except "locked" "entersearch" "search" "renametab" "renamepane" "session" {
              bind "o" { SwitchToMode "session"; }
          }
          shared_except "locked" "tab" "entersearch" "renametab" "renamepane" {
              bind "t" { SwitchToMode "tab"; }
          }
          shared_among "normal" "resize" "tab" "scroll" "prompt" "tmux" {
              bind "p" { SwitchToMode "pane"; }
          }
          shared_among "normal" "resize" "search" "move" "prompt" "tmux" {
              bind "s" { SwitchToMode "scroll"; }
          }
          shared_except "locked" "resize" "pane" "tab" "entersearch" "renametab" "renamepane" {
              bind "r" { SwitchToMode "resize"; }
          }
          shared_among "scroll" "search" {
              bind "PageDown" { PageScrollDown; }
              bind "PageUp" { PageScrollUp; }
              bind "left" { PageScrollUp; }
              bind "down" { ScrollDown; }
              bind "up" { ScrollUp; }
              bind "right" { PageScrollDown; }
              bind "Ctrl b" { PageScrollUp; }
              bind "Ctrl c" { ScrollToBottom; SwitchToMode "locked"; }
              bind "d" { HalfPageScrollDown; }
              bind "Ctrl f" { PageScrollDown; }
              bind "h" { PageScrollUp; }
              bind "j" { ScrollDown; }
              bind "k" { ScrollUp; }
              bind "l" { PageScrollDown; }
              bind "u" { HalfPageScrollUp; }
          }
          entersearch {
              bind "Ctrl c" { SwitchToMode "scroll"; }
              bind "esc" { SwitchToMode "scroll"; }
              bind "enter" { SwitchToMode "search"; }
          }
          renametab {
              bind "esc" { UndoRenameTab; SwitchToMode "tab"; }
          }
          shared_among "renametab" "renamepane" {
              bind "Ctrl c" { SwitchToMode "locked"; }
          }
          renamepane {
              bind "esc" { UndoRenamePane; SwitchToMode "pane"; }
          }
      }
      load_plugins {}
    '';
  };
}
