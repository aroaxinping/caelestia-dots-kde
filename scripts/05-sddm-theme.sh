#!/usr/bin/env bash
# 05-sddm-theme.sh - Install the Caelestia SDDM greeter theme
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/log.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/privileges.sh"

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"

if [[ "${INSTALL_SDDM:-false}" != "true" ]]; then
    skip "SDDM theme not selected."
    exit 0
fi

echo
info "Installing Caelestia SDDM theme"
echo

SDDM_REPO="https://github.com/aroaxinping/caelestia-sddm.git"
SDDM_DIR="$BUNDLE_DIR/sddm-theme"
THEME_NAME="caelestia"
INSTALL_DIR="/usr/share/sddm/themes/$THEME_NAME"
SYNC_SCRIPT="$INSTALL_DIR/scripts/sync.sh"
THEME_SOURCE="$SDDM_DIR/themes/full"

# Clone or update
if [[ -d "$SDDM_DIR/.git" ]]; then
    git -C "$SDDM_DIR" pull --ff-only 2>/dev/null || {
        rm -rf "$SDDM_DIR"
        git clone --depth 1 "$SDDM_REPO" "$SDDM_DIR"
    }
else
    rm -rf "$SDDM_DIR"
    git clone --depth 1 "$SDDM_REPO" "$SDDM_DIR"
fi
ok "Cloned SDDM theme repo."

# Dependencies (arch only for now)
if [[ "${BASE_DISTRO:-}" == "arch" ]]; then
    SDDM_DEPS=(sddm qt6-declarative qt6-5compat qt6-svg qt6-multimedia)
    MISSING=()
    for pkg in "${SDDM_DEPS[@]}"; do
        if ! pacman -Qq "$pkg" &>/dev/null; then
            MISSING+=("$pkg")
        fi
    done
    if [[ ${#MISSING[@]} -gt 0 ]]; then
        info "Installing SDDM dependencies: ${MISSING[*]}"
        caelestia_sudo pacman -S --noconfirm "${MISSING[@]}"
    fi
    ok "Dependencies met."
fi

# Clean previous install
if [[ -d "$INSTALL_DIR" ]]; then
    caelestia_sudo rm -rf "$INSTALL_DIR"
fi

# Copy theme
caelestia_sudo mkdir -p "$INSTALL_DIR/scripts"
caelestia_sudo cp -r "$THEME_SOURCE"/* "$INSTALL_DIR/"
caelestia_sudo cp "$SDDM_DIR/scripts/sync.sh" "$INSTALL_DIR/scripts/"

# Permissions
caelestia_sudo find "$INSTALL_DIR" -type d -exec chmod 755 {} +
caelestia_sudo find "$INSTALL_DIR" -type f -exec chmod 644 {} +
caelestia_sudo chmod 755 "$SYNC_SCRIPT"
ok "Theme files installed to $INSTALL_DIR"

# Template config
mkdir -p "$HOME/.config/caelestia/templates"
if [[ -f "$THEME_SOURCE/theme.conf.template" ]]; then
    cp "$THEME_SOURCE/theme.conf.template" "$HOME/.config/caelestia/templates/sddm-theme.conf"
    ok "Template config created."
fi

# SDDM drop-in
caelestia_sudo mkdir -p /etc/sddm.conf.d
cat <<'DROPIN' | caelestia_sudo tee /etc/sddm.conf.d/caelestia.conf >/dev/null
[General]
GreeterEnvironment=QML_XHR_ALLOW_FILE_READ=1

[Theme]
Current=caelestia
DROPIN
ok "SDDM config drop-in created."

# Posthook registration
POSTHOOK_CMD="sudo $SYNC_SCRIPT --posthook"
CLI_JSON="$HOME/.config/caelestia/cli.json"

if command -v python3 &>/dev/null; then
    python3 - "$CLI_JSON" "$POSTHOOK_CMD" <<'PYEOF'
import json, sys, os
cli_path, hook_cmd = sys.argv[1], sys.argv[2]
config = {}
if os.path.exists(cli_path):
    with open(cli_path) as f:
        config = json.load(f)
for section in ("wallpaper", "theme"):
    if section not in config:
        config[section] = {}
    config[section]["postHook"] = hook_cmd
os.makedirs(os.path.dirname(cli_path), exist_ok=True)
with open(cli_path, "w") as f:
    json.dump(config, f, indent=4)
PYEOF
    ok "Posthook registered in cli.json"
fi

# Passwordless sudo for sync
SUDOERS_FILE="/etc/sudoers.d/caelestia-sddm-sync"
if ! caelestia_sudo_quiet test -f "$SUDOERS_FILE"; then
    echo "$USER ALL=(root) NOPASSWD: $SYNC_SCRIPT" | caelestia_sudo tee "$SUDOERS_FILE" >/dev/null
    caelestia_sudo chmod 440 "$SUDOERS_FILE"
    ok "Sudoers drop-in created."
fi

# Initial sync
if caelestia_sudo "$SYNC_SCRIPT"; then
    ok "Initial sync complete."
else
    warn "Initial sync had warnings (non-fatal)."
fi

ok "SDDM theme installed."
