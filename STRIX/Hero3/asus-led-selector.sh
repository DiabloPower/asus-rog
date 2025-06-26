#!/bin/bash

OPENRGB="/usr/local/bin/openrgb"
ENV_FILE="$HOME/.config/asus-rgb/env.conf"
mkdir -p "$(dirname "$ENV_FILE")"

# Optionaler Gerätewechsel
if [[ "$1" == "--choose-device" ]]; then
  CHOOSE_DEVICE=1
fi

MODES=("Static" "Breathing" "Spectrum Cycle" "Rainbow Wave" "Starry Night" "Reactive - Ripple" "Comet" "Off")
TITLE="Select ASUS Ambient Light Mode"
SELECTED=""
COLOR_STRING=""

COLOR_REQUIRED_MODES=("Static" "Breathing" "Comet" "Reactive - Ripple")
MULTICOLOR_MODES=("Spectrum Cycle" "Rainbow Wave")

# ---------------------- DEVICE HANDLING ----------------------

detect_device() {
  local device_lines options

  mapfile -t device_lines < <("$OPENRGB" --list-devices | grep -E '^[0-9]+:')

  if [[ ${#device_lines[@]} -eq 0 ]]; then
    echo "No RGB devices detected by OpenRGB." >&2
    exit 1
  fi

  if use_zenity; then
    for line in "${device_lines[@]}"; do
      id=$(echo "$line" | cut -d: -f1)
      name=$(echo "$line" | cut -d: -f2- | sed 's/^ *//')
      options+=("FALSE" "$id" "$name")
    done

    DEVICE_ID=$(zenity --list --radiolist \
      --width=350 --height=400 \
      --title="Select RGB Device" \
      --text="Choose your target RGB device:" \
      --column="Select" --column="ID" --column="Device Name" \
      "${options[@]}")
  else
    echo "Available RGB devices:"
    for i in "${!device_lines[@]}"; do
      echo "$i) ${device_lines[$i]}"
    done
    read -rp "Select device number: " choice
    DEVICE_ID=$(echo "${device_lines[$choice]}" | cut -d: -f1)
  fi

  if [[ -n "$DEVICE_ID" ]]; then
    echo "DEVICE_ID=$DEVICE_ID" > "$ENV_FILE"
  else
    echo "No device selected. Exiting."
    exit 1
  fi
}

load_device_id() {
  if [[ -f "$ENV_FILE" && -z "$CHOOSE_DEVICE" ]]; then
    source "$ENV_FILE"
    echo "Using saved device: $DEVICE_ID"
  else
    detect_device
  fi
}

# ---------------------- ENV + UI ----------------------

has_display() {
  [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]
}

install_if_missing() {
  local pkg=$1
  if ! command -v "$pkg" >/dev/null; then
    echo "Installing missing dependency: $pkg"
    if command -v apt >/dev/null; then
      sudo apt update && sudo apt install -y "$pkg"
    elif command -v pacman >/dev/null; then
      sudo pacman -S --noconfirm "$pkg"
    elif command -v dnf >/dev/null; then
      sudo dnf install -y "$pkg"
    elif command -v zypper >/dev/null; then
      sudo zypper install -y "$pkg"
    else
      echo "No compatible package manager found. Install '$pkg' manually."
    fi
  fi
}

use_zenity() { has_display && install_if_missing zenity && command -v zenity >/dev/null; }
use_dialog() { install_if_missing dialog && command -v dialog >/dev/null; }

show_menu_zenity() {
  local zenity_items=()
  for mode in "${MODES[@]}"; do
    zenity_items+=("FALSE" "$mode")
  done

  zenity --list --radiolist \
    --width=350 --height=400 \
    --title="$TITLE" \
    --text="Choose your desired lighting mode:" \
    --column="Select" --column="Mode" \
    "${zenity_items[@]}"
}

show_menu_dialog() {
  dialog --menu "$TITLE" 15 50 8 \
    "${!MODES[@]}" "${MODES[@]}" 2>tmp_selection.txt
  retval=$?
  if [[ $retval -eq 0 ]]; then
    SELECTED="${MODES[$(cat tmp_selection.txt)]}"
    rm tmp_selection.txt
  fi
}

show_menu_basic() {
  echo "$TITLE"
  select opt in "${MODES[@]}"; do
    if [[ -n "$opt" ]]; then SELECTED="$opt"; break; fi
  done
}

requires_color() {
  for mode in "${COLOR_REQUIRED_MODES[@]}"; do
    [[ "$SELECTED" == "$mode" ]] && return 0
  done
  return 1
}

requires_multicolor() {
  for mode in "${MULTICOLOR_MODES[@]}"; do
    [[ "$SELECTED" == "$mode" ]] && return 0
  done
  return 1
}

get_color_input() {
  local prompt="$1" color_pick r g b
  if use_zenity; then
    color_pick=$(zenity --color-selection --title="$prompt")
    if [[ "$color_pick" =~ ^# ]]; then
      echo "${color_pick:1}"
    elif [[ "$color_pick" =~ rgb ]]; then
      r=$(echo "$color_pick" | sed -E 's/rgb\(([0-9]+),.*/\1/')
      g=$(echo "$color_pick" | sed -E 's/rgb\([0-9]+, *([0-9]+),.*/\1/')
      b=$(echo "$color_pick" | sed -E 's/.*,\s*([0-9]+)\)/\1/')
      printf "%02X%02X%02X\n" "$r" "$g" "$b"
    else
      echo ""
    fi
  else
    read -rp "$prompt (hex RGB, e.g. FF0000): " color_pick
    echo "${color_pick/#\#}"
  fi
}

# ---------------------- MAIN ----------------------

load_device_id
#echo "DEBUG: Loaded DEVICE_ID='$DEVICE_ID'"

if use_zenity; then
  SELECTED=$(show_menu_zenity)
elif use_dialog; then
  show_menu_dialog
else
  show_menu_basic
fi

if [[ -n "$SELECTED" ]]; then
  echo "Selected mode: $SELECTED"

  if requires_multicolor; then
    COLOR1=$(get_color_input "Choose first color")
    COLOR2=$(get_color_input "Choose second color")
    COLOR_STRING="$COLOR1,$COLOR2"
  elif requires_color; then
    COLOR1=$(get_color_input "Choose primary color")
    COLOR_STRING="$COLOR1"
  fi

  echo "Applying '$SELECTED' mode to device $DEVICE_ID..."
  #printf "DEBUG: Selected raw mode='%s'\n" "$SELECTED"
  
  # Safety-Off, if mode is frozen
  "$OPENRGB" --device "$DEVICE_ID" --mode Off >/dev/null
  sleep 0.2
  
  if [[ -n "$COLOR_STRING" ]]; then
    "$OPENRGB" --device "$DEVICE_ID" --mode "$SELECTED" --color "$COLOR_STRING" >/dev/null
  else
    "$OPENRGB" --device "$DEVICE_ID" --mode "$SELECTED" >/dev/null
  fi
  echo "Done."
else
  echo "No mode selected. Exiting."
fi
