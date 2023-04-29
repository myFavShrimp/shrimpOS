#!/bin/bash
RELEASEVER="$(rpm -E %fedora)"
BASEARCH="$(rpm -E %_arch)"

# TODO: add repo url && fix `ostree remote add` command
echo "--- Install packages ---"

echo "-- Install Alacritty --"
ostree remote add alacritty https://download.copr.fedorainfracloud.org/results/atim/alacritty/fedora-$RELEASEVER-$BASEARCH/
rpm-ostree install alacritty

echo "-- Install helix --"
# use fedora 38 helix as no package is available for fedora 39
HELIX_RELEASEVER=38
ostree remote add helix-editor https://download.copr.fedorainfracloud.org/results/varlad/helix/fedora-$HELIX_RELEASEVER-$BASEARCH/
rpm-ostree install helix

echo "-- Install starship --"
curl -sS https://starship.rs/install.sh | sh -s -s -- -y
echo "---"
