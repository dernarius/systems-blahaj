{ config, pkgs, pkgs-unstable, lib, ... }:
{
  environment.systemPackages = with pkgs-unstable; [
    boilr
    lunar-client
    lutris
    modrinth-app
    pcsx2
  ];
}
