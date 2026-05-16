{ config, pkgs, pkgs-unstable, lib, ... }:
let
  stable = with pkgs; [
    boilr
    lunar-client
    modrinth-app
    pcsx2
    lutris
  ];
  unstable = with pkgs-unstable; [
  ];
in {
  environment.systemPackages = stable ++ unstable;
}
