# asus-rog
Asus ROG Linux Scripts....


## asus-led-selector.sh

A simple but flexible RGB mode selector script for **ASUS ROG laptops on Linux**, tested on the **ROG Strix Hero III (G731GU / G533ZM)**.  
It uses OpenRGB to apply lighting effects to the **keyboard and ambient light controller**, with a friendly interactive menu.

### ✅ Features

- Graphical or terminal-based **RGB effect selector**
- Works with `zenity`, `dialog`, or plain shell input
- Lets you choose from popular ASUS lighting modes
- Remembers your selected RGB device across sessions
- Auto-detects available OpenRGB devices at launch
- Optionally re-choose your device with a command-line flag

### 📦 Dependencies

- [OpenRGB](https://openrgb.org/)
- Optional: `zenity` (GTK GUI), `dialog` (ncurses UI)

The script installs missing dependencies where possible.

### 🔧 Usage

```bash
./asus-led-selector.sh
```

Or, to re-select your OpenRGB device:

```bash
./asus-led-selector.sh --choose-device
```

At first launch, it will list all OpenRGB-compatible devices and let you pick the one you want to control. This selection is saved to `~/.config/asus-rgb/env.conf`.

Example output:

```
Using saved device: 5
Choose your desired lighting mode:
[ ] Static
[ ] Breathing
[ ] Rainbow Wave
...
```

### ⚠️ Note on ASUS Device Naming

Depending on your system, the lighting controller may appear as:

- `G533ZM`
- `ASUS Aura Keyboard`
- or another name entirely

OpenRGB sometimes lists several nearly identical devices (e.g. multiple HID keyboards), so you may need to try each to find the one controlling your ambient or keyboard lighting.

### 🎯 Compatibility

- Verified on: **ROG Strix Hero III (G731GU / G533ZM)**
- Likely compatible with other ASUS ROG laptops and keyboards using ASUS Aura lighting
- Some modes in the list may not be supported by your device or may behave differently
- In rare cases, lighting may appear to freeze or not respond — the script resets the mode to "Off" before setting a new one as a workaround

### 📥 Download

You can fetch the script directly using:

```bash
wget https://raw.githubusercontent.com/DiabloPower/asus-rog/main/STRIX/Hero3/asus-led-selector.sh
chmod +x asus-led-selector.sh
```

Then run it with:

```bash
./asus-led-selector.sh
```

> ✅ No GitHub login required — the raw file is publicly accessible.
