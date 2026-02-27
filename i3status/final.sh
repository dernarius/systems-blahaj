#!/usr/bin/env bash

i3status | while :
do
  read line
  lang="$(swaymsg -rt get_inputs | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name ' | head -n 1)"
  echo "$lang $line" || exit 1
done
