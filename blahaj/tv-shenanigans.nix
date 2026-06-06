{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "toggle-tv-mode" ''

      # fix headless
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

      # Get current TTY
      CURRENT_TTY=$(cat /sys/class/tty/tty0/active | tr -dc '0-9')

      set_audio_default() {
        local search_name="$1"
        local node_id=$(wpctl status | grep -m 1 -i "$search_name" | awk -F'.' '{print $1}' | awk '{print $NF}')
        
        if [ -n "$node_id" ]; then
          wpctl set-default "$node_id"
          echo "Routed audio to $search_name (ID: $node_id)"
        else
          echo "Warning: Could not find audio device '$search_name'"
        fi
      }

      if [ "$CURRENT_TTY" -eq 1 ]; then
        echo "Switching to TV Mode..."
        pkill steam
        sleep 2 

        # Using absolute paths injected by Nix to perfectly match sudo rules
        sudo ${pkgs.systemd}/bin/systemctl start tv-session.service
        sudo ${pkgs.kbd}/bin/chvt 8

        set_audio_default "Navi 48 HDMI/DP Audio Controller Digital Stereo (HDMI)"

      else
        echo "Switching to Desk Mode..."
        (
          sleep 1
          sudo ${pkgs.systemd}/bin/systemctl stop tv-session.service
          set_audio_default "ArturiaMsd Analog Stereo"
          sudo ${pkgs.kbd}/bin/chvt 1
          nohup steam > /dev/null 2>&1 &
        ) </dev/null >/dev/null 2>&1 & disown
      fi
    '')
  ];

  systemd.services.tv-session = {
    description = "Gamescope TV Session";
    # Ensure it doesn't conflict with a login prompt
    conflicts = [ "getty@tty8.service" ];

    serviceConfig = {
      User = "stk"; # REPLACE WITH YOUR USERNAME
      PAMName = "login";
      TTYPath = "/dev/tty8";
      StandardInput = "tty";
      StandardOutput = "journal";
      StandardError = "journal";
      UtmpIdentifier = "tty8";
      UtmpMode = "user";
      Type = "simple";

      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];

      # The magic command. Adjust the -W and -H to your TV's resolution.
      # You may need to verify the output name (-O) is exactly HDMI-A-1 using swaymsg -t get_outputs
      ExecStart = "${pkgs.gamescope}/bin/gamescope -e -W 3840 -H 2160 -r 60 -O HDMI-A-1 -- ${pkgs.libcap}/bin/capsh --caps= -- -c 'exec ${pkgs.steam}/bin/steam -gamepadui'";
      Restart = "no";
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "stk" ];
      commands = [
        {
          command = "${pkgs.kbd}/bin/chvt";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl start tv-session.service";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl stop tv-session.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  systemd.services.mode-switcher-api = {
    description = "HTTP API for TV Mode Switching";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    path = [
      "/run/wrappers"
      "/run/current-system/sw"
    ];

    serviceConfig = {
      User = "stk"; # IMPORTANT: Run as your user so the sudo rules work!
      Restart = "always";
    };

    script = ''
      ${pkgs.python3}/bin/python -c '
      import http.server, socketserver, subprocess

      class APIHandler(http.server.BaseHTTPRequestHandler):
          def do_GET(self):
              if self.path == "/toggle":
                  self.send_response(200)
                  self.send_header("Content-type", "text/plain")
                  self.end_headers()
                  self.wfile.write(b"Executing toggle script...\n")
                  
                  # Run the script in the background so the HTTP request finishes instantly
                  subprocess.Popen(["/run/current-system/sw/bin/toggle-tv-mode"])
              else:
                  self.send_response(404)
                  self.end_headers()

      # Listen on all network interfaces on port 8080
      print("Starting Mode Switcher API on port 8080...")
      socketserver.TCPServer(("", 8080), APIHandler).serve_forever()
      '
    '';
  };
}
