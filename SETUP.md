# Caelestia on Void Linux — Setup Guide

Caelestia is built for Arch (pacman/AUR, systemd). Void uses XBPS and runit, and
ships **GCC 14** — while current Hyprland assumes GCC 15 (C++26). This guide
documents every step taken to get a fully working Caelestia desktop on Void.

> Run a full system update first: `sudo xbps-install -Suy`

---

## 1. Packages from the Void repos

Toolchain + everything Caelestia/Hyprland needs that *is* packaged:

```
base-devel cmake meson ninja pkgconf git zig
wayland-devel wayland-protocols pixman-devel libdrm-devel libinput-devel
libxkbcommon-devel cairo-devel pango-devel libdisplay-info-devel libseat-devel
libliftoff-devel tomlplusplus tomlplusplus-devel re2 re2-devel muparser-devel
lcms2-devel libuuid-devel hyprutils hyprwayland-scanner glslang-devel
SPIRV-Tools-devel SPIRV-Headers libzip-devel pugixml-devel librsvg-devel
file-devel libmagic fftw-devel iniparser-devel glm libgbm-devel Vulkan-Headers
qt6-base-devel qt6-declarative-devel qt6-shadertools qt6-wayland-devel
qt6-base-private-devel qt6-declarative-private-devel qt6-wayland-private-devel
cli11 jemalloc-devel cpptrace-devel libqalculate-devel aubio-devel pipewire-devel
pam-devel polkit-devel glib-devel mesa mesa-dri xorg-server-xwayland

quickshell-deps + runtime:
ddcutil brightnessctl libqalculate qalculate fish-shell swappy grim slurp
wl-clipboard foot hyprpicker matugen cliphist inotify-tools wireplumber pipewire
trash-cli eza fastfetch starship btop jq papirus-icon-theme dconf libnotify
lm_sensors power-profiles-daemon python3 python3-Pillow python3-pip fuzzel
polkit-gnome gnome-keyring elogind xdg-desktop-portal xdg-desktop-portal-gtk
qt6-svg qt6-wayland qt5ct qt6ct gammastep geoclue2 gsettings-desktop-schemas
gpu-screen-recorder upower bluez psmisc xdg-utils noto-fonts-ttf flatpak
```

---

## 2. Greeter — `ly`

`ly` is not packaged for Void. Built from source:

- Needs **Zig 0.16** — Void ships 0.13, so the official Zig 0.16.0 tarball is
  downloaded and used directly.
- `zig build installexe -Dinit_system=runit -Denable_x11_support=false -Ddefault_tty=2 -Dfallback_tty=2`
- Installs the binary, `/etc/ly/`, `/etc/pam.d/ly` (PAM file is Void-compatible —
  `-` prefixes skip missing modules; `pam_elogind.so` registers the session),
  and the runit service `/etc/sv/ly`.
- Configured for **tty2** (`/etc/sv/ly/conf`). `agetty-tty2` is disabled so ly
  owns tty2; `agetty-tty1` stays as a console.

---

## 3. Hyprland — built from source

Hyprland is **not packaged for Void** at all. The whole ecosystem is built:

### Library chain (CMake, install to `/usr`)

`hyprutils` → `hyprlang` → `hyprgraphics` → `hyprcursor` → `aquamarine` →
`hyprland-protocols` → `hyprwire` → **Hyprland 0.55.1** → `xdg-desktop-portal-hyprland`.

`hyprutils` is rebuilt from source (HEAD ≥ 0.13.1; Void packages 0.11.0).

### GCC 14 / C++26 patches

Hyprland 0.55.1 targets GCC 15. Void has GCC 14, missing three C++26 features:

1. **`operator+(string, string_view)`** (P2591) — provided by a force-included
   shim, `void-build/cxx26compat.hpp`, passed via
   `-DCMAKE_CXX_FLAGS="-include .../cxx26compat.hpp"`.
2. **`insert_range`** — one call in `src/helpers/Monitor.cpp` rewritten to
   `insert(end(), ranges::begin(r), ranges::end(r))`.
3. **`#embed`** — `src/config/lua/DefaultConfig.hpp` `#embed` replaced with the
   literal byte array of `example/hyprland.lua`.

Also: `hyprctl/src/main.cpp` `string + string_view` (fixed by the shim);
`src/xwayland/XWM.hpp:220` ternary type mismatch fixed with an explicit
`static_cast<xcb_connection_t*>`.

**`hyprwire`** (new Hyprland dep) uses `std::vector::append_range` (C++23 lib,
absent in libstdc++ 14) — all call sites rewritten to `insert(end(), …)`.

### Lua 5.5

Hyprland 0.55 requires Lua 5.5; Void ships 5.4. Lua 5.5.0 is built from source
(`make linux MYCFLAGS="-fPIC -O2"`, installed to `/usr`) with a hand-written
`/usr/lib/pkgconfig/lua5.5.pc`.

### libcava

caelestia-shell's beat detector links `libcava`, which Void's `cava` package
doesn't provide. Built from the `LukashonakV/cava` fork (`meson -Dbuild_target=lib`).

`hyprland-qtutils` is also built from source (provides `hyprland-dialog`,
`hyprland-share-picker`, etc.).

---

## 4. Quickshell + caelestia-shell

- **Quickshell**: built from **git master** (caelestia requires the git build,
  not a tagged release). Needs the Qt6 `*-private-devel` packages. The packaged
  `quickshell` is removed first.
- **caelestia-shell**: `git clone` → CMake build → install to `/etc/xdg/quickshell/caelestia`
  + the `Caelestia` QML plugin to `/usr/lib/qt6/qml/Caelestia`.
- **caelestia-cli**: `pip install --break-system-packages .` (pulls `materialyoucolor`).

---

## 5. Void adaptations (the Arch-isms)

| Arch assumption | Void fix |
|-----------------|----------|
| `app2unit` (systemd transient units) | Replaced with a direct-launch script at `/usr/local/bin/app2unit` — apps still launch, minus cgroup scoping |
| Power actions use `systemctl` | Patched to `loginctl` in the shell sources (`sessionconfig.hpp`, `launcherconfig.hpp`, `generalconfig.hpp`, `BatteryMonitor.qml`); VPN daemon start → `sv up` |
| PipeWire via systemd user services | Started from the Hyprland session — see `config/caelestia/hypr-user.conf` |
| `uwsm` (systemd-only) | Skipped; `hyprland-uwsm.desktop` removed |
| Session has no D-Bus bus | Session launched via `dbus-run-session` (the `hyprland.desktop` Exec) |
| polkit-gnome / geoclue paths | Fixed to Void's `/usr/libexec/...` in `hypr/hyprland/execs.conf` |
| GPU autodetect uses `&>` (bash-ism, breaks under dash) | `services.gpuType` forced to `generic` in `shell.json` |

---

## 6. Services (runit)

Enable by symlinking into `/var/service`:

```
elogind  polkitd  power-profiles-daemon  bluetoothd  ly
```

(`dbus`, `NetworkManager`, `udevd` are already enabled on a default install.)

### Seat / device access

elogind installed *after* boot means udev never tagged the DRM/input devices for
`seat0` — Hyprland then can't acquire the GPU. Fix (also correct on every boot
since the rules are now in place):

```
sudo udevadm control --reload
sudo udevadm trigger --action=add
```

---

## 7. Fonts

Installed to `/usr/share/fonts/caelestia/` (+ `fc-cache -f`):

- **Material Symbols Rounded** — the shell's icon font
- **CaskaydiaCove Nerd Font** — shell mono
- **Rubik** — shell UI/clock font
- **JetBrains Mono Nerd Font** — terminal font (foot)
- **Noto Sans Symbols 2** (via `noto-fonts-ttf`) — fallback for the
  Miscellaneous-Technical glyphs Claude Code and others use (`⏵ ⏺ ⎿` …)

---

## 8. Applications

- **Zen Browser (Twilight)** — `/opt/zen`, launcher `zen-browser`
- **Equibop** (Discord) — `/opt/equibop`, launcher `equibop`
- **Spotify** — Flatpak (`com.spotify.Client`)
- **Claude Desktop** — community Linux build (`patrickjaja/claude-desktop-bin`),
  `/opt/claude-desktop`, launcher `claude-desktop` (sets `CLAUDE_DISABLE_SYSTEMD_SCOPE=1`)
- **Thunar** + gvfs/tumbler — file manager
- **Neovim + LazyVim**
- **dart-sass** — `/opt/dart-sass` (for Caelestia's Discord theming)

---

## 9. VPN — sing-box

`system/sing-box/config.json` is a VLESS + REALITY client config for sing-box,
run as the runit service `/etc/sv/sing-box` with a TUN inbound. The Caelestia
shell's VPN tab toggles it.

> **The committed config is sanitized** — `uuid`, `server`, `public_key` and
> `short_id` are placeholders. Fill in your own and place it at
> `/etc/sing-box/config.json`.

---

## 10. Customizations

Set in `config/caelestia/hypr-vars.conf` / `hypr-user.conf` / `cli.json` /
`shell.json`:

- Cursor: **Bibata-Modern-Classic**
- App launcher on **Alt+Space**; Claude toggle on **Super+Shift+F23** (Copilot key)
- Special-workspace toggles wired to installed apps: Spotify (Super+M),
  Equibop (Super+D), Claude Desktop
- 3-finger workspace swipe; **hypr-dynamic-cursors** plugin (tilt mode)
- Square window corners, zero gaps, no transparency
- fastfetch shows the Void logo beside the info box
- Dark mode forced (adw-gtk3-dark, `prefer-dark`, qt6ct)

---

## 11. Power menu — Boot into Windows button

The Caelestia power menu (`modules/session/`) has a custom **Boot into
Windows** button — a one-shot reboot into the Windows install that never
touches the permanent EFI `BootOrder`.

**How it works.** A small root helper sets the EFI `BootNext` variable to
the "Windows Boot Manager" entry, then reboots. `BootNext` is consumed by
the firmware after exactly one boot, so the boot *after* Windows returns to
Void automatically. The button runs the helper through a NOPASSWD `sudo`
rule, so it's a single click with no password prompt.

| Repo file | Deploys to |
|-----------|------------|
| `shell/modules/session/Content.qml` | `/etc/xdg/quickshell/caelestia/modules/session/Content.qml` |
| `system/boot-windows/caelestia-boot-windows` | `/usr/local/bin/caelestia-boot-windows` (root, `0755`) |
| `system/boot-windows/caelestia-boot-windows.sudoers` | `/etc/sudoers.d/caelestia-boot-windows` (root, `0440`) |

Deploy:

```sh
sudo install -m 0755 -o root -g root \
    system/boot-windows/caelestia-boot-windows /usr/local/bin/caelestia-boot-windows
sudo install -m 0440 -o root -g root \
    system/boot-windows/caelestia-boot-windows.sudoers /etc/sudoers.d/caelestia-boot-windows
sudo visudo -c                                       # sanity-check sudoers
sudo cp shell/modules/session/Content.qml \
    /etc/xdg/quickshell/caelestia/modules/session/Content.qml
caelestia shell -k && caelestia shell -d             # restart the shell
```

Test the helper without rebooting:

```sh
sudo -n /usr/local/bin/caelestia-boot-windows --dry-run
```

> `shell/modules/session/Content.qml` is the **first vendored shell
> modification** in this repo — a patched copy of the upstream
> `caelestia-dots/shell` module. The `loginctl` power-action patches from
> §5 are documented but not yet vendored here.

---

## Deploying this repo

```sh
git clone <this-repo> ~/caelestia-void
cd ~/caelestia-void
./install.sh          # symlinks config/ and caelestia/ into place
```

`install.sh` only places the config files — the software in sections 2–4 must
be built first.
