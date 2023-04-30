#!/bin/bash
RELEASEVER="$(rpm -E %fedora)"
BASEARCH="$(rpm -E %_arch)"

echo "--- Remove packages ---"
rpm-ostree uninstall just
echo "---"

echo "--- Install packages ---"
# shrimpos
echo "-- Install shrimpos --"
rpm-ostree install /var/shrimpos.rpm -y --force-replacefiles
# coprs
echo "-- Install Alacritty --"
rpm-ostree install alacritty -y
echo "-- Install helix --"
rpm-ostree install helix -y
echo "---"

echo "--- Cloning myFavShrimp/cfg ---"
cd /tmp
git clone https://github.com/myFavShrimp/cfg.git
cd cfg
echo "--- Installing default gnome settings ---"
mkdir -p /usr/etc/dconf/db/local.d
cp gnome/* /usr/etc/dconf/db/local.d/
echo "--- Installing extensions ---"
make extensions
echo "--- Installing flatpaks ---"
make flatpaks
echo "--- Updating dconf databases ---"
dconf update
echo "---"
