{ config, pkgs, pkgs-unstable, lib, ... }:
{
  environment.systemPackages = [
    pkgs-unstable.boilr
    pkgs-unstable.lunar-client
    pkgs.lutris
    pkgs-unstable.modrinth-app
    pkgs-unstable.pcsx2
  ];
}
