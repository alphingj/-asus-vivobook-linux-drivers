#!/usr/bin/env bash
#
# Vivobook Go E1404FA - one-command Linux setup for NumberPad, fan and LED.
#
# One-liner (inspect first, then run):
#   curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/install.sh | bash
#
# Or from a clone:
#   git clone https://github.com/<you>/<repo>.git && cd <repo> && ./install.sh
#
# What it does (safe by default):
#   1. installs distro deps (i2c-tools, python3, libevdev, curl)
#   2. enables i2c-dev and finds the ASUP1411 touchpad bus (expects 0x15)
#   3. adds you to i2c/input/uinput groups (needs re-login after)
#   4. installs upstream asus-numberpad-driver with E1404FA hints
#   5. reports fan/thermal status via asus-wmi (read-only)
# I2C backlight writes only happen in the interactive device check and
# --led-test, both of which ask before touching hardware.
#
# Flags:
#   --check-only   detect hardware and exit, change nothing
#   --numpad       set up NumberPad (default when no feature flag given)
#   --fan          fan/thermal detection report (default when no flag given)
#   --led-test     interactive backlight/LED sweep (asks first)
#   --bus N        override detected i2c bus number
#   --addr HH      override i2c address hex (default 15)
#   --yes          skip confirmation prompts (still never writes blindly)
#   --help         this text

set -euo pipefail

UPSTREAM="https://github.com/asus-linux-drivers/asus-numberpad-driver.git"
SRC_DIR="${SRC_DIR:-$HOME/.local/src}"
CLONE_DIR="$SRC_DIR/asus-numberpad-driver"

BUS="" ADDR="15" YES=0 CHECK_ONLY=0
WANT_NUMPAD=0 WANT_FAN=0 WANT_LED=0

log()  { printf '[e1404fa] %s\n' "$*"; }
warn() { printf '[e1404fa][warn] %s\n' "$*" >&2; }
die()  { printf '[e1404fa][err] %s\n' "$*" >&2; exit 1; }
ask()  { # ask <prompt> -> 0=yes; auto-yes with --yes (reads /dev/tty for curl|bash)
  [ "$YES" = "1" ] && return 0
  local ans=""; printf '[e1404fa] %s [y/N] ' "$1" > /dev/tty
  read -r ans < /dev/tty || true
  [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

while [ $# -gt 0 ]; do
  case "$1" in
    --check-only) CHECK_ONLY=1 ;;
    --numpad) WANT_NUMPAD=1 ;;
    --fan) WANT_FAN=1 ;;
    --led-test) WANT_LED=1 ;;
    --yes) YES=1 ;;
    --bus) BUS="${2:?--bus needs a number}"; shift ;;
    --addr) ADDR="${2:?--addr needs hex like 15}"; shift ;;
    --help|-h) sed -n '2,28p' "$0"; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done
if [ "$WANT_NUMPAD$WANT_FAN$WANT_LED" = "000" ]; then WANT_NUMPAD=1; WANT_FAN=1; fi

command -v sudo >/dev/null || die "sudo is required"
[ -f /etc/os-release ] || die "no /etc/os-release, unsupported distro"
# shellcheck disable=SC1091
. /etc/os-release
log "distro: ${NAME:-$ID} ($ID), kernel: $(uname -r)"

install_deps() {
  log "installing dependencies..."
  case "$ID $ID_LIKE" in
    *debian*|*ubuntu*)
      sudo apt-get update
      sudo apt-get install -y i2c-tools python3 python3-venv libevdev2 curl ;;
    *arch*)
      sudo pacman -Sy --needed --noconfirm i2c-tools python python-virtualenv libevdev curl ;;
    *fedora*|*rhel*|*centos*)
      sudo dnf install -y i2c-tools python3 python3-virtualenv libevdev curl ;;
    *suse*|*opensuse*)
      sudo zypper --non-interactive install i2c-tools python3 libevdev curl ;;
    *) warn "unknown distro; install manually: i2c-tools python3 libevdev curl" ;;
  esac
}

ensure_i2c() {
  sudo modprobe i2c-dev 2>/dev/null || true
  ls /dev/i2c-* >/dev/null 2>&1 || die "no /dev/i2c-* nodes; is i2c-dev loaded?"
  log "i2c nodes: $(echo /dev/i2c-* | tr ' ' ',')"
}

detect_touchpad() {
  local dev=/proc/bus/input/devices
  [ -f "$dev" ] || die "$dev missing (not Linux or no input layer)"
  local blk
  blk="$(grep -B1 -A6 -i touchpad "$dev" | grep -B1 -A6 -i -E 'ASUP1411|093A|ASUE14|ELAN' | head -20 || true)"
  [ -n "$blk" ] || die "no ASUS/PixArt touchpad found in $dev"
  log "touchpad block:"; printf '%s\n' "$blk" | sed 's/^/[e1404fa]   /'
  if [ -z "$BUS" ]; then
    BUS="$(printf '%s\n' "$blk" | grep -o -E 'i2c-[0-9]+' | head -1 | cut -d- -f2 || true)"
    [ -n "$BUS" ] || die "could not parse i2c bus; pass --bus N"
  fi
  if printf '%s\n' "$blk" | grep -q -E 'ASUF1416|ASUF1205|ASUF1204'; then ADDR="38"; fi
  log "using bus i2c-$BUS addr 0x$ADDR"
}

ensure_groups() {
  for g in i2c input uinput; do
    if getent group "$g" >/dev/null; then
      if id -nG "$USER" | tr ' ' '\n' | grep -qx "$g"; then log "group $g: ok"
      else sudo usermod -aG "$g" "$USER"; log "added $USER to $g (re-login to apply)"; fi
    else warn "group $g does not exist on this distro, skipping"; fi
  done
}

install_numpad() {
  mkdir -p "$SRC_DIR"
  if [ -d "$CLONE_DIR/.git" ]; then log "updating upstream driver..."; git -C "$CLONE_DIR" pull --ff-only
  else log "cloning upstream driver..."; git clone --depth 1 "$UPSTREAM" "$CLONE_DIR"; fi
  log "running upstream device check (interactive, watches the pad)..."
  ( cd "$CLONE_DIR" && bash install_device_check.sh ) || warn "device check exited nonzero; continuing"
  log "running upstream installer..."
  ( cd "$CLONE_DIR" && bash install.sh )
  # E1404FA preset: keep last-used brightness across restarts
  local cfg=/usr/share/asus-numberpad-driver/numberpad_dev
  if [ -f "$cfg" ]; then
    sudo sed -i 's/^default_backlight_level.*/default_backlight_level = 0x01/' "$cfg" \
      || echo 'default_backlight_level = 0x01' | sudo tee -a "$cfg" >/dev/null
    log "preset applied: default_backlight_level = 0x01 in $cfg"
  fi
  {
    echo "E1404FA note: pick the 5-column layout matching your printed grid;"
    echo "brightness family to try first: 0x41-0x48 at i2c-$BUS 0x$ADDR.";
    echo "bus=$BUS addr=$ADDR detected $(date -u +%FT%TZ)"
  } | sudo tee /usr/share/asus-numberpad-driver/E1404FA.txt >/dev/null 2>&1 || true
  log "NumberPad done. If keys are offset, re-run upstream install and try the next 5-column layout."
}

fan_report() {
  log "fan/thermal report (read-only):"
  local found=0
  for d in /sys/devices/platform/asus*; do
    [ -d "$d" ] || continue; found=1
    log "platform: $d"
    for f in fan_boost_mode throttle_thermal_policy; do
      [ -f "$d/$f" ] && log "  $f = $(cat "$d/$f" 2>/dev/null || echo '?')"
    done
  done
  [ "$found" = "1" ] || warn "no asus platform device; asus-wmi may not have bound (check dmesg | grep -i asus)"
  if command -v sensors >/dev/null; then sensors 2>/dev/null | grep -i -E 'temp|fan|k10|amdgpu' | head -10 | sed 's/^/[e1404fa]   /' || true
  else warn "lm_sensors not installed; temps unreadable (optional: install lm-sensors)"; fi
  if command -v asusctl >/dev/null; then log "asusctl present: $(asusctl --version 2>/dev/null | head -1)"
  else log "asusctl not installed (optional). See fan/README.md for profile mapping."; fi
  log "Fn+F5 on this model cycles the same mode the OS writes via fan_boost_mode/throttle_thermal_policy."
}

led_test() {
  command -v /usr/sbin/i2ctransfer >/dev/null || die "i2ctransfer missing (install i2c-tools)"
  ask "send test backlight frames to i2c-$BUS @ 0x$ADDR while you watch the pad?" || { log "led test skipped"; return; }
  local v
  for v in 01 60 41 42 43 44 45 46 47 48 20 2f; do
    printf '[e1404fa] sending 0x%s (watch pad + corner LED)...\n' "$v"
    sudo /usr/sbin/i2ctransfer -f -y "$BUS" "w13@0x$ADDR" \
      0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 "0x$v" 0xad || warn "transfer 0x$v failed"
    printf '[e1404fa] change? [y/N] ' > /dev/tty; read -r v < /dev/tty || true
  done
  sudo /usr/sbin/i2ctransfer -f -y "$BUS" "w13@0x$ADDR" \
    0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad || true
  log "restored 0x00 (off). Record which value lit what in touchpad-led/README.md table."
}

main() {
  detect_touchpad
  if [ "$CHECK_ONLY" = "1" ]; then
    log "check-only: bus=i2c-$BUS addr=0x$ADDR; no changes made."
    [ "$WANT_FAN" = "1" ] && fan_report || true
    exit 0
  fi
  install_deps
  ensure_i2c
  ensure_groups
  [ "$WANT_NUMPAD" = "1" ] && install_numpad || true
  [ "$WANT_FAN" = "1" ] && fan_report || true
  [ "$WANT_LED" = "1" ] && led_test || true
  log "done. Re-login for group changes, then test: hold the pad top-right icon ~1s."
}
main
