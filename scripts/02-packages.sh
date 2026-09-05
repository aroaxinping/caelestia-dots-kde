#!/usr/bin/env bash
# 02-packages.sh - Install Caelestia lock screen greeter and ensure Python tooling
# (Package groups are installed by the individual 02-*-packages.sh scripts)

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/privileges.sh"

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

echo
echo ""
info "Installing Caelestia lock screen greeter & Python tooling"
echo ""

# Remove deprecated plasma-wallpaper-application if present
if command -v kpackagetool6 >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Wallpaper -r net.dosowisko.PlasmaApplicationWallpaper >/dev/null 2>&1 || true
fi
rm -rf "$HOME/.local/share/plasma/wallpapers/net.dosowisko.PlasmaApplicationWallpaper" 2>/dev/null || true
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/wallpaper-plugin-installed" 2>/dev/null || true

if [[ "${APPLY_LOCKSCREEN:-true}" != "false" ]]; then
    info "Installing Caelestia lock screen greeter..."
    SHELL_SRC="$BUNDLE_DIR/src/kde/shells/caelestia.desktop"
    SHELL_DEST="$HOME/.local/share/plasma/shells/caelestia.desktop"
    if [[ -d "$SHELL_SRC" ]]; then
        mkdir -p "$(dirname "$SHELL_DEST")"
        rm -rf "$SHELL_DEST"
        cp -r "$SHELL_SRC" "$SHELL_DEST"
        if command -v kwriteconfig6 >/dev/null 2>&1; then
            kwriteconfig6 --file kscreenlockerrc --group "Greeter" --key "Theme" --delete 2>/dev/null || true
            kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin "org.kde.image" 2>/dev/null || true
            kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group net.dosowisko.PlasmaApplicationWallpaper --group General --key command --delete 2>/dev/null || true
            kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group net.dosowisko.PlasmaApplicationWallpaper --group General --key fps --delete 2>/dev/null || true
            kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key alwaysShowClock --delete 2>/dev/null || true
            kwriteconfig6 --file kscreenlockerrc --group Greeter --group LnF --group General --key showMediaControls --delete 2>/dev/null || true
            kwriteconfig6 --file plasmashellrc --group "Shell" --key "ShellPackage" "caelestia.desktop" 2>/dev/null || true
        fi
        ok "Caelestia lock screen greeter installed."
    else
        warn "Caelestia lock screen greeter source not found: $SHELL_SRC"
    fi
else
    skip "Lock screen greeter disabled by user choice."
fi

echo

info "Ensuring Python tooling for konsave backups"
if ! command -v python3 >/dev/null 2>&1 || ! python3 -m pip --version >/dev/null 2>&1; then
    package_distro="${BASE_DISTRO:-}"
    if [[ -z "$package_distro" ]]; then
        if command -v pacman >/dev/null 2>&1; then
            package_distro="arch"
        elif command -v dnf >/dev/null 2>&1; then
            package_distro="fedora"
        elif command -v apt-get >/dev/null 2>&1; then
            package_distro="debian"
        fi
    fi

    if [[ "$package_distro" == "arch" ]]; then
        caelestia_sudo pacman -S --needed --noconfirm python python-pip
    elif [[ "$package_distro" == "fedora" ]]; then
        caelestia_sudo dnf install -y python3 python3-pip
    elif [[ "$package_distro" == "debian" ]]; then
        caelestia_sudo apt-get update && caelestia_sudo apt-get install -y python3 python3-pip python3-venv
    else
        warn "Could not determine the distro for Python tooling installation."
    fi
fi

echo
ok "Package installation complete."
