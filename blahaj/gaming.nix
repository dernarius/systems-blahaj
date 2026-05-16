{ config, pkgs, pkgs-unstable, lib, ... }:
let
  stable = with pkgs; [
    boilr
    lunar-client
    modrinth-app
    pcsx2
  ];
  unstable = with pkgs-unstable; [
    lutris
  ];
in {
  environment.systemPackages = stable ++ unstable;
}
