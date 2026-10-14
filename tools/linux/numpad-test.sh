#!/usr/bin/env bash
# Read-only-first NumberPad backlight sweep helper (Linux).
# Usage: confirm BUS + ADDR with install_device_check.sh FIRST, then:
#   sudo tools/linux/numpad-test.sh <bus-number> [addr-hex, default 15]
# Sends upstream 13-byte frames one at a time and asks you to watch the pad.
# Values: 01 (on) + 60 (unlock) are sent first, then brightness candidates.
set -u
BUS="${1:?usage: numpad-test.sh <bus-number> [addr-hex]}"
ADDR="${2:-15}"
send() { # $1 = value hex
  echo "--- sending 0x$1 to i2c-$BUS @ 0x$ADDR (watch the pad) ---"
  sudo /usr/sbin/i2ctransfer -f -y "$BUS" "w13@0x$ADDR" \
    0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 "0x$1" 0xad
  read -r -p "Any change? [y/N] " ok < /dev/tty
  [ "${ok:-N}" = "y" ] || [ "${ok:-N}" = "Y" ] && echo "VALUE 0x$1 DID SOMETHING" && return 0
  return 1
}
send 01; send 60
for v in 41 42 43 44 45 46 47 48 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f; do
  send "$v" && break
done
echo "Restore with: sudo i2ctransfer -f -y $BUS w13@0x$ADDR 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
