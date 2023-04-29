#!/bin/bash
RELEASEVER="$(rpm -E %fedora)"
BASEARCH="$(rpm -E %_arch)"

echo "--- Install packages ---"
# shrimpos
echo "-- Install shrimpos --"
rpm-ostree install /var/shrimpos.rpm -y

# coprs
echo "-- Install Alacritty --"
rpm-ostree install alacritty -y

echo "-- Install helix --"
rpm-ostree install helix -y

echo "---"
