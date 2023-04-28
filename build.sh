#!/bin/bash
echo "-- Installing RPMs defined in recipe.yml --"
rpm_packages=$(yq '.rpms[]' < /tmp/shrimpos-recipe.yml)
for pkg in $(echo -e "$rpm_packages"); do \
    echo "Installing: ${pkg}" && \
    rpm-ostree install $pkg; \
done
echo "---"

releasever="$(rpm -E %fedora)"
basearch="$(rpm -E %_arch)"

# TODO: add repo url && fix `ostree remote add` command
echo "--- Install packages ---"

echo "-- Install Alacritty --"
ostree remote add alacritty https://download.copr.fedorainfracloud.org/results/atim/alacritty/fedora-$releasever-$basearch/
rpm-ostree install alacritty

echo "-- Install helix --"
ostree remote add helix-editor https://download.copr.fedorainfracloud.org/results/varlad/helix/fedora-$releasever-$basearch/
rpm-ostree install helix

echo "-- Install starship --"
curl -sS https://starship.rs/install.sh | sh -s -s -- -y
echo "---"
