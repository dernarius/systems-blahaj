{ config, pkgs, pkgs-unstable, lib, ... }:
let
in {
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama-rocm;
  };
}
