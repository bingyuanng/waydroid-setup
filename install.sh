#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=config.env
source "$repo_dir/config.env"

WIDTH=${WIDTH:-480}
HEIGHT=${HEIGHT:-1071}
DENSITY=${DENSITY:-186}
MAX_FPS=${MAX_FPS:-120}
FAKE_TOUCH=${FAKE_TOUCH:-'*'}
MULTI_WINDOWS=${MULTI_WINDOWS:-false}
IMAGE_FLAVOR=${IMAGE_FLAVOR:-GAPPS}
INSTALL_HOUDINI=${INSTALL_HOUDINI:-true}
INSTALL_MAGISK=${INSTALL_MAGISK:-true}
ENABLE_KWIN_RULE=${ENABLE_KWIN_RULE:-true}
WAYDROID_SCRIPT_COMMIT=48dbfaf34a6ddbe78688c530f9ba1c26522aafb2

if [[ ${EUID} -eq 0 ]]; then
  printf 'Run this script as your desktop user, not as root. It will use sudo when needed.\n' >&2
  exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
  printf 'This installer supports Arch Linux and Arch-based distributions only.\n' >&2
  exit 1
fi

for value in "$WIDTH" "$HEIGHT" "$DENSITY" "$MAX_FPS"; do
  [[ $value =~ ^[1-9][0-9]*$ ]] || {
    printf 'Display values must be positive integers.\n' >&2
    exit 1
  }
done
[[ $MULTI_WINDOWS == true || $MULTI_WINDOWS == false ]] || {
  printf 'MULTI_WINDOWS must be true or false.\n' >&2
  exit 1
}

printf 'Installing host dependencies...\n'
sudo -v
sudo pacman -S --needed --noconfirm waydroid android-tools lzip git python

if [[ ! -f /var/lib/waydroid/waydroid.cfg ]]; then
  printf 'Initializing the %s Waydroid image...\n' "$IMAGE_FLAVOR"
  sudo waydroid init -s "$IMAGE_FLAVOR"
else
  printf 'Using the existing initialized Waydroid image.\n'
fi

waydroid session stop >/dev/null 2>&1 || true
sudo systemctl stop waydroid-container.service

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/waydroid-setup.XXXXXX")
cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ $INSTALL_HOUDINI == true || $INSTALL_MAGISK == true ]]; then
  printf 'Preparing pinned Waydroid Extras installer...\n'
  git clone --quiet https://github.com/casualsnek/waydroid_script.git "$work_dir/waydroid_script"
  git -C "$work_dir/waydroid_script" checkout --quiet "$WAYDROID_SCRIPT_COMMIT"
  python -m venv "$work_dir/venv"
  "$work_dir/venv/bin/pip" install --quiet --requirement "$work_dir/waydroid_script/requirements.txt"

  cd "$work_dir/waydroid_script"

  if [[ $INSTALL_HOUDINI == true ]]; then
    printf 'Installing Houdini ARM32/ARM64 translation...\n'
    sudo "$work_dir/venv/bin/python" "$work_dir/waydroid_script/main.py" install libhoudini
  fi
  if [[ $INSTALL_MAGISK == true ]]; then
    printf 'Installing Magisk Delta...\n'
    sudo "$work_dir/venv/bin/python" "$work_dir/waydroid_script/main.py" install magisk
  fi
  cd "$repo_dir"
fi

printf 'Writing persistent Waydroid properties...\n'
sudo python "$repo_dir/scripts/configure-waydroid.py" \
  --width "$WIDTH" \
  --height "$HEIGHT" \
  --max-fps "$MAX_FPS" \
  --fake-touch "$FAKE_TOUCH" \
  --multi-windows "$MULTI_WINDOWS"
sudo waydroid upgrade -o

config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/android-sim
install -d -m 0755 "$HOME/.local/bin" "$config_dir"
install -m 0755 "$repo_dir/bin/android-sim" "$HOME/.local/bin/android-sim"
if [[ ! -f $config_dir/config ]]; then
  install -m 0644 "$repo_dir/config.env" "$config_dir/config"
fi

if [[ $ENABLE_KWIN_RULE == true && ${XDG_CURRENT_DESKTOP:-} == *KDE* ]]; then
  python "$repo_dir/scripts/configure-kwin-rule.py" --width "$WIDTH" --height "$HEIGHT"
  if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  fi
fi

sudo systemctl enable --now waydroid-container.service
printf '\nInstallation complete. Start with: android-sim run\n'
printf 'Fake touch is enabled globally with the Waydroid wildcard: %s\n' "$FAKE_TOUCH"
printf 'The first launch may take longer while Android initializes.\n'
