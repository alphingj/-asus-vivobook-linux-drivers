# Contributing — E1404FA findings

Per-revision reports are the point of this repo: ASUS ships several
touchpad revisions under one laptop model. A good report lets the next
owner skip the whole sweep.

## What to include

- Laptop sub-model + BIOS version (`E1404FA.318` style)
- Touchpad block from `/proc/bus/input/devices` (name, `Phys`, `Handlers`)
- Detected `bus=i2c-N`, `addr=0x..`
- Working brightness set + layout name (NumberPad)
- `DSTS` hex per fan ID (`0x00110019`, `0x00110018`, `0x00120075`,
  `0x00110011`) + which profiles switch
- Corner LED: grid yes/no per value, LED yes/no per value
- Kernel + distro (`uname -r`, `/etc/os-release`)

## What to scrub

- Machine serial (`IdentifyingNumber`), Windows keys, DSDT UUIDs and any
  personalization before posting logs or `DSDT.dsl` snippets.
- Never attach ASUS binaries (`.sys/.exe/.dll/.inf/.cat`) — names and
  versions only (`.gitignore` already blocks them).

## How

- Small PRs: one revision or one feature per PR.
- Keep facts where they belong (`numpad/`, `fan/`, `touchpad-led/`);
  link from `docs/` instead of copying.
- Scripts: ASCII-only, `bash -n` clean, read-only default, ask before
  any hardware write (see `install.sh` flags as the pattern).
