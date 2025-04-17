#!/usr/bin/env bash
set -euo pipefail

# Define directories
APPDIR="$HOME/appimages"
BINDIR="$HOME/.local/bin"

mkdir -p "$APPDIR" "$BINDIR"
cd "$APPDIR"

# List of AppImages to download
packages=(
    "https://github.com/nelsonenzo/tmux-appimage/releases/download/3.2a/tmux.appimage"
    "https://github.com/Syllo/nvtop/releases/download/3.0.2/nvtop-x86_64.AppImage"
)

# Download and link
for url in "${packages[@]}"; do
    filename="${url##*/}"         # extract file name from URL
    shortname="${filename%%.*}"  # remove .AppImage or other suffix

    wget -q --show-progress -N "$url"
    chmod +x "$filename"

    # Create or update symlink in ~/.local/bin
    ln -sf "$APPDIR/$filename" "$BINDIR/$shortname"
done
