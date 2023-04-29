#!/bin/bash
RELEASEVER="$(rpm -E %fedora)"
BASEARCH="$(rpm -E %_arch)"

# TODO: add repo url && fix `ostree remote add` command
echo "--- Install packages ---"

# coprs
echo "-- Install Alacritty --"
rpm-ostree install alacritty -y

echo "-- Install helix --"
rpm-ostree install helix -y

echo "-- Install starship --"
curl -sS https://starship.rs/install.sh | sh -s -s -- -y
echo "---"
