#!/usr/bin/env bash

# if [ "$EUID" -ne 0 ]
#   then echo "Please run as root"
#   exit
# fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd $SCRIPT_DIR

echo "starting update"

nix flake update

git add .
git commit -m "flake update"

# export NIXPKGS_ALLOW_BROKEN=1
sudo nixos-rebuild switch --flake .#blahaj
