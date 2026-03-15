# cdl-niri

A [Quickshell](https://quickshell.outfoxxed.me/) desktop shell built for [niri](https://github.com/YaLTeR/niri) — a scrollable-tiling Wayland compositor.

Adapted and extended from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)'s `illogical-impulse` shell, which was originally designed for Hyprland. This project ports and reworks that shell to run natively on niri, replacing all Hyprland-specific IPC and compositor integrations.

![Shell screenshot placeholder](assets/)

---

## Features

- **Bar** — clock, workspaces, system tray, media controls, quick toggles, network/battery/audio indicators
- **Left sidebar** — AI chat assistant, translator
- **Right sidebar** — quick toggles, volume mixer, Bluetooth devices, Wi-Fi networks, night light, system info
- **Overview / launcher** — app search, window search, clipboard, emoji picker, integrated with niri workspaces
- **Notification popups** — with action buttons and per-app icons
- **Lock screen** — built-in Quickshell lock with blur effect and clock
- **Session screen** — power off, reboot, suspend, logout
- **Wallpaper selector** — thumbnail browser with Material You color generation
- **On-screen display** — brightness, volume, keyboard backlight
- **Screen corners** — fake rounded screen corners overlay
- **Cheatsheet** — keybind reference viewer (parses niri KDL config)
- **Media controls overlay** — full-screen album art + controls
- **Polkit agent** — graphical privilege escalation dialogs
- **Region selector** — screenshot, OCR, screen recording

## Visual styles

- **Material** — opaque panels themed by Material You colors generated from the wallpaper
- **Glass** — frosted/tinted panel style:
  - Bar uses client-side wallpaper blur (blurred wallpaper slice rendered behind the panel)
  - Sidebars use a configurable solid color overlay with per-panel color and opacity controls

> **Note on blur:** niri does not currently implement `ext-background-effect-v1` or any compositor-side blur protocol. True blur of window content behind panels is not possible without compositor support. The bar's wallpaper blur is the maximum achievable today; sidebar panels use a solid tinted background as a clean alternative.

## Requirements

- [niri](https://github.com/YaLTeR/niri) (tested on 25.11)
- [Quickshell](https://quickshell.outfoxxed.me/) (`noctalia-qs` fork, 0.0.5+, Qt 6.10+)
- `matugen` — Material You color generation from wallpaper
- `python3` with `materialyoucolor`, `pillow`, `numpy`, `opencv-python-headless`
- `grimblast` or `grim` + `slurp` — screenshots
- `wl-clipboard`, `cliphist` — clipboard history
- `playerctl` — MPRIS media control
- `brightnessctl` — screen brightness
- `nmcli` (NetworkManager) — network management
- `bluez` / `bluetoothctl` — Bluetooth
- `pipewire` + `wireplumber` — audio

## Installation

```bash
git clone https://github.com/yourusername/cdl-niri ~/repos/cdl-niri
ln -s ~/repos/cdl-niri ~/.config/quickshell/cdl-niri
```

Set up the Python venv:

```bash
python3 -m venv ~/.venv/cdl-niri
source ~/.venv/cdl-niri/bin/activate
pip install materialyoucolor pillow numpy opencv-python-headless
```

Launch:

```bash
qs -c cdl-niri
```

## IPC

Control the shell from niri keybinds or scripts via `qs ipc call`:

```bash
qs -c cdl-niri ipc call sidebarLeft toggle
qs -c cdl-niri ipc call sidebarRight toggle
qs -c cdl-niri ipc call search toggle
qs -c cdl-niri ipc call session toggle
qs -c cdl-niri ipc call wallpaperSelector toggle
qs -c cdl-niri ipc call brightness increment
qs -c cdl-niri ipc call brightness decrement
qs -c cdl-niri ipc call region screenshot
```

## Configuration

Shell config lives at `~/.config/cdl-niri/config.json`. Most options are accessible through the built-in Quick Config panel (open the right sidebar → settings icon) or the full settings window:

```bash
qs -p ~/repos/cdl-niri/settings.qml
```

## Credits & Inspiration

- **[end-4](https://github.com/end-4)** — for [dots-hyprland](https://github.com/end-4/dots-hyprland) and the `illogical-impulse` shell, which is the direct foundation this project is built on. The module structure, widget library, service architecture, and overall design language all originate from his work.

- **[YaLTeR](https://github.com/YaLTeR)** — for [niri](https://github.com/YaLTeR/niri), the compositor this shell is built for. The scrollable-tiling model and clean IPC design made this port a pleasure to work on.

- **[outfoxxed](https://github.com/outfoxxed)** — for [Quickshell](https://quickshell.outfoxxed.me/), the QML shell framework that makes all of this possible.

## License

See [LICENSE](LICENSE).
