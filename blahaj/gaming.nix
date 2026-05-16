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
  nixpkgs.overlays = [
    (_: prev: {
      openldap = prev.openldap.overrideAttrs {
        doCheck = false; # False is a bit more honest on x86_64 systems
      };
    })
  ];
  environment.systemPackages = stable ++ unstable;
}
