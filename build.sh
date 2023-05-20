#!/bin/bash

echo "--- Remove packages ---"
rpm-ostree uninstall just
echo "---"

echo "--- Install packages ---"
# coprs
echo "-- Install Alacritty --"
rpm-ostree install alacritty -y
echo "-- Install helix --"
rpm-ostree install helix -y
echo "---"
