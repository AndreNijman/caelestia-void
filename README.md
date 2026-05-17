# caelestia-void

My custom desktop shell — the [Caelestia](https://github.com/caelestia-dots/caelestia)
Hyprland setup, fully ported to **Void Linux** (Caelestia targets Arch).

A ThinkPad running Void with Hyprland + the Quickshell-based Caelestia shell,
the `ly` greeter, and a pile of customizations. Everything that isn't packaged
for Void was built from source and patched to compile with Void's GCC 14.

## What's here

| Path | What it is |
|------|------------|
| `caelestia/` | The Caelestia dotfiles (my modified fork) → deploy to `~/.local/share/caelestia` |
| `shell/` | Patched Caelestia Quickshell modules (vendored) — **Boot into Windows** power-menu button + **disable-touchpad-while-typing** quick toggle |
| `config/caelestia/` | Personal overrides → `~/.config/caelestia/` (`hypr-user.conf`, `hypr-vars.conf`, `hypr-dwt.conf`, `cli.json`, `shell.json`) |
| `config/caelestia/schemes/` | Custom colour schemes — `goldnight` (gold on `#1a1b1e`) and `ember` (amber-accent monochrome) |
| `config/gtk-3.0`, `config/gtk-4.0` | Dark-mode GTK settings |
| `config/qt5ct`, `config/qt6ct` | Qt dark-mode settings |
| `config/mimeapps.list` | Default apps (browser, file manager) |
| `system/sing-box/` | sing-box VPN config (**credentials sanitized** — fill in your own) |
| `system/boot-windows/` | "Boot into Windows" helper + sudoers rule for the power-menu button |
| `void-build/` | The GCC 14 / C++26 compatibility shim used to build Hyprland |
| `SETUP.md` | Full guide — how the whole thing was built and adapted for Void |

## Quick start

This is **not** a one-command install — Hyprland and friends have to be built
from source on Void. Read **[SETUP.md](SETUP.md)** for the full process.

The config files themselves can be deployed with `./install.sh` once the
software is in place.

## Stack

- **Void Linux** · runit · elogind
- **Hyprland 0.55.1** (built from source)
- **Quickshell** (git) + **caelestia-shell** + **caelestia-cli**
- **ly** greeter (built from source)
- Apps: Zen Browser, Equibop, Spotify, Claude Desktop, Thunar, Neovim/LazyVim
