#!/bin/bash

echo "--- Updating dconf databases ---"
dconf update
echo "---"

echo "--- Setting up user service ---"
root_directory="/home"
subdirectories=$(ls "${root_directory}")

for subdir in $subdirectories; do
  new_directory="${root_directory}/${subdir}/.config/autostart"
  mkdir -p "$new_directory"
  cp -rf /etc/shrimpos/shrimpos.desktop "$new_directory"
done
echo "---"
