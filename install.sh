#!/usr/bin/env bash
# Xenoglyph — Animated Wallpaper: install.  ./install.sh
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/scorn.xenoglyph" "${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/Xenoglyph"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers" "${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
cp -r "$HERE/animated" "${XDG_DATA_HOME:-$HOME/.local/share}/plasma/wallpapers/scorn.xenoglyph"
cp -r "$HERE/still" "${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers/Xenoglyph"
echo "Installed. Right-click the desktop > Desktop and Wallpaper > Xenoglyph (animated)."
