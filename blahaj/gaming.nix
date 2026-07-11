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
    modrinth-app
    pcsx2
    steam-rom-manager
    wineWow64Packages.stable
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
