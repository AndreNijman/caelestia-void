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

# Touchpad disable-while-typing state — a mutable runtime file (rewritten
# by the control-centre quick toggle), so seed it only if absent. It must
# be a real copy, never a symlink, or toggling would dirty the repo.
if [ ! -e "$CONFIG/caelestia/hypr-dwt.conf" ]; then
    mkdir -p "$CONFIG/caelestia"
    cp "$REPO/config/caelestia/hypr-dwt.conf" "$CONFIG/caelestia/hypr-dwt.conf"
    echo "seeded: $CONFIG/caelestia/hypr-dwt.conf"
fi

# GTK / Qt / mime
link "$REPO/config/gtk-3.0/settings.ini" "$CONFIG/gtk-3.0/settings.ini"
link "$REPO/config/gtk-4.0/settings.ini" "$CONFIG/gtk-4.0/settings.ini"
link "$REPO/config/qt5ct/qt5ct.conf"     "$CONFIG/qt5ct/qt5ct.conf"
link "$REPO/config/qt6ct/qt6ct.conf"     "$CONFIG/qt6ct/qt6ct.conf"
link "$REPO/config/mimeapps.list"        "$CONFIG/mimeapps.list"

# Custom colour schemes -> caelestia-cli's bundled schemes dir, so they
# appear in `caelestia scheme set` and the shell's scheme picker. The CLI
# data dir lives inside the Python package, so this needs sudo and is
# wiped by a `caelestia-cli` upgrade — just rerun this script to restore.
CLI_SCHEMES="$(python3 -c 'import caelestia, os; print(os.path.join(os.path.dirname(caelestia.__file__), "data", "schemes"))' 2>/dev/null || true)"
if [ -n "$CLI_SCHEMES" ] && [ -d "$REPO/config/caelestia/schemes" ]; then
    for s in "$REPO"/config/caelestia/schemes/*/; do
        [ -d "$s" ] || continue
        name="$(basename "$s")"
        sudo cp -rT "$s" "$CLI_SCHEMES/$name"
        echo "installed scheme: $name -> $CLI_SCHEMES/$name"
    done
else
    echo "skip: caelestia-cli not found, custom schemes not installed"
fi

# Vendored Caelestia shell module patches -> /etc/xdg/quickshell/caelestia.
# Root-owned target, so this needs sudo. Restart the shell afterwards with
# `caelestia shell -k && caelestia shell -d`.
if [ -d "$REPO/shell" ]; then
    ( cd "$REPO/shell" && find . -type f ) | while IFS= read -r f; do
        f="${f#./}"
        sudo install -Dm644 "$REPO/shell/$f" "/etc/xdg/quickshell/caelestia/$f"
        echo "patched shell module: $f"
    done
fi

cat <<'EOF'

Config deployed.

Still to do by hand:
  - Symlink the Caelestia config dirs into ~/.config (hypr, foot, fish,
    fastfetch, btop, starship.toml) — see the Caelestia install steps.
  - Place a real sing-box config at /etc/sing-box/config.json
    (system/sing-box/config.json here has placeholder credentials).
  - Pick a colour scheme: `caelestia scheme set -n goldnight` (or ember).
  - Restart the shell to load vendored module patches:
    `caelestia shell -k && caelestia shell -d`.
EOF
