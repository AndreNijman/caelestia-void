#!/bin/sh
# Symlink the config files from this repo into place.
# NOTE: this only deploys configuration — the software (Hyprland, Quickshell,
# caelestia-shell, ly …) must be built/installed first. See SETUP.md.
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
    src="$1"; dst="$2"
    [ -e "$src" ] || { echo "skip (missing): $src"; return; }
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%s)"
        echo "backed up existing: $dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    echo "linked: $dst"
}

# Caelestia dotfiles repo
link "$REPO/caelestia" "$HOME/.local/share/caelestia"

# ~/.config/caelestia overrides
for f in hypr-user.conf hypr-vars.conf cli.json shell.json; do
    link "$REPO/config/caelestia/$f" "$CONFIG/caelestia/$f"
done

# GTK / Qt / mime
link "$REPO/config/gtk-3.0/settings.ini" "$CONFIG/gtk-3.0/settings.ini"
link "$REPO/config/gtk-4.0/settings.ini" "$CONFIG/gtk-4.0/settings.ini"
link "$REPO/config/qt5ct/qt5ct.conf"     "$CONFIG/qt5ct/qt5ct.conf"
link "$REPO/config/qt6ct/qt6ct.conf"     "$CONFIG/qt6ct/qt6ct.conf"
link "$REPO/config/mimeapps.list"        "$CONFIG/mimeapps.list"

cat <<'EOF'

Config deployed.

Still to do by hand:
  - Symlink the Caelestia config dirs into ~/.config (hypr, foot, fish,
    fastfetch, btop, starship.toml) — see the Caelestia install steps.
  - Place a real sing-box config at /etc/sing-box/config.json
    (system/sing-box/config.json here has placeholder credentials).
EOF
