{ config, pkgs, lib, ... }:
let 
  scripts = lib.mapAttrs (name: value: pkgs.writeScriptBin name (builtins.readFile value)) {
    cpu = ./scripts/cpu;
    battery = ./scripts/battery;
    disk = ./scripts/disk;
  };
in
{
  programs.i3blocks = {
    enable = true;

    bars.config = {
      cpu = {
	label = "[cpu]";
	command = "${scripts.cpu}/bin/cpu";
	color = "#DCD7BA";
	interval = 60;
      };

      memory = lib.hm.dag.entryAfter [ "cpu" ] {
	label = "[mem]";
	command = "echo $(free -m | awk 'NR==2{printf \"%.2f%%\t\t\", $3*100/$2 }')";
	interval = 60;
	color = "#DCD7BA";
      };

      disk = lib.hm.dag.entryAfter [ "memory" ] {
	label = "[disk]";
	command = "${scripts.disk}/bin/disk";
	interval = 600;
	color = "#DCD7BA";
      };

      time = lib.hm.dag.entryAfter [ "disk" ] {
	command = "date '+%a %x %I:%M%P'";
	color = "#7E9CD8";
	interval = 60;
      };

      battery = lib.hm.dag.entryAfter [ "time" ] {
	command = "${scripts.battery}/bin/battery";
	markup = "pango";
	instance = "BAT0";
	interval = 60;
      };
    };
  };
}
