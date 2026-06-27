{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  stable = with pkgs; [
    lunar-client
    pcsx2
    steam-rom-manager
    wineWowPackages.stable
    winetricks
  ];
  unstable = with pkgs-unstable; [
    boilr
    lutris
  ];
in
{
  environment.systemPackages = stable ++ unstable;
}
