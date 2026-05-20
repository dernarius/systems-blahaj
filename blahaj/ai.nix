{ config, pkgs, pkgs-unstable, lib, ... }:
let
  stable = with pkgs; [
    searxng
  ];
  unstable = with pkgs-unstable; [
    aider-chat
    openclaw
  ];
in {
  environment.systemPackages = stable ++ unstable;
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-rocm;
  };
}
