{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    boilr
    lunar-client
    lutris
    modrinth-app
    pcsx2
  ];
}
