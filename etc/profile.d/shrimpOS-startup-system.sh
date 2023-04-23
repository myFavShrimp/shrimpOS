# if test "$(id -u)" -gt "0" && test -d "$HOME"; then
#     if test ! -e "$HOME"/.config/autostart/shrimpOS-startup-system.desktop; then
#         mkdir -p "$HOME"/.config/autostart
#         cp -f /etc/skel.d/.config/autostart/shrimpOS-startup-system.desktop "$HOME"/.config/autostart
#     fi
# fi

just -f /etc/shrimpos/justfile setup-flatpaks
