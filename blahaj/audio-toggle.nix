{
  config,
  pkgs,
  lib,
  ...
}:
let
  # The two JCally JM6 Pro II DACs are physically identical and report the same
  # USB serial ("Synaptics_JM6PRO_2"), so PipeWire's sink names (...-00 vs
  # ...-00.2) and ALSA card numbers depend on enumeration order and shuffle
  # between boots. The USB port each one is plugged into is the only stable
  # way to tell them apart, so match on that instead.
  #
  # Ports come from the sink's `api.alsa.card.longname`, e.g.
  #   "Synaptics JM6PRO_2 at usb-0000:02:00.0-1.1.2.3, high speed"
  # If you ever swap the two DACs between USB ports, swap these two values.
  speakersPort = "1.1.2.3";
  headphonesPort = "1.1.2.2";

  toggleAudioOutput = pkgs.writeShellScriptBin "toggle-audio-output" ''
    set -euo pipefail

    # usable when launched from rofi/a keybind, where the session env is thin
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

    pactl=${pkgs.pulseaudio}/bin/pactl
    pw_dump=${pkgs.pipewire}/bin/pw-dump
    jq=${pkgs.jq}/bin/jq
    notify=${pkgs.libnotify}/bin/notify-send

    # Name of the Audio/Sink sitting on a given USB port, empty if unplugged.
    sink_on_port() {
      $pw_dump | $jq -r --arg port "$1" '
        [ .[]
          | select(.type == "PipeWire:Interface:Node")
          | .info.props
          | select(.["media.class"] == "Audio/Sink")
          | select((.["api.alsa.card.longname"] // "") | contains("-" + $port + ","))
          | .["node.name"] ]
        | first // empty'
    }

    speakers=$(sink_on_port ${speakersPort})
    headphones=$(sink_on_port ${headphonesPort})
    current=$($pactl get-default-sink || true)

    case "''${1:-toggle}" in
      speakers)
        label="Speakers"
        target="$speakers"
        ;;
      headphones)
        label="Headphones"
        target="$headphones"
        ;;
      toggle)
        # Anything other than the speakers being current (headphones, HDMI,
        # nothing at all) toggles to the speakers.
        if [ -n "$speakers" ] && [ "$current" = "$speakers" ]; then
          label="Headphones"
          target="$headphones"
        else
          label="Speakers"
          target="$speakers"
        fi
        ;;
      status)
        if [ -n "$speakers" ] && [ "$current" = "$speakers" ]; then
          echo "Speakers"
        elif [ -n "$headphones" ] && [ "$current" = "$headphones" ]; then
          echo "Headphones"
        else
          echo "Other ($current)"
        fi
        exit 0
        ;;
      *)
        echo "usage: toggle-audio-output [toggle|speakers|headphones|status]" >&2
        exit 2
        ;;
    esac

    if [ -z "$target" ]; then
      echo "No JM6 Pro II found for $label" >&2
      $notify -u critical -i audio-card "Audio output" "$label DAC is not connected" || true
      exit 1
    fi

    $pactl set-default-sink "$target"

    # Move whatever is already playing, so the switch is immediate.
    $pactl list short sink-inputs | cut -f1 | while read -r stream; do
      $pactl move-sink-input "$stream" "$target" || true
    done

    if [ "$label" = "Headphones" ]; then
      icon=audio-headphones
    else
      icon=audio-speakers
    fi
    $notify -i "$icon" "Audio output" "Switched to $label" || true
  '';

  toggleAudioOutputDesktop = pkgs.makeDesktopItem {
    name = "toggle-audio-output";
    desktopName = "Toggle Audio Output";
    comment = "Switch the default output between the speaker and headphone DAC";
    exec = "${toggleAudioOutput}/bin/toggle-audio-output";
    icon = "audio-headphones";
    terminal = false;
    categories = [
      "AudioVideo"
      "Audio"
      "Settings"
    ];
    keywords = [
      "audio"
      "sound"
      "output"
      "sink"
      "speakers"
      "headphones"
      "dac"
      "toggle"
    ];
  };
in
{
  environment.systemPackages = [
    toggleAudioOutput
    toggleAudioOutputDesktop
  ];
}
