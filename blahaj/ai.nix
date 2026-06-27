{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  stable = with pkgs; [
  ];
  unstable = with pkgs-unstable; [
  ];
in
{
  environment.systemPackages = stable ++ unstable;
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-rocm;
  };
}
