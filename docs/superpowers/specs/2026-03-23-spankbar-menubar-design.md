# SpankBar Menu Bar App — Design Spec

**Date:** 2026-03-23
**Status:** Approved
**Repo:** `~/Projects/spank-sfwn`

---

## Overview

Add a macOS menu bar app (SpankBar) that lets the user switch spank audio packs and toggle settings without touching the command line. A rewritten process supervisor replaces the existing `spank-wrapper` shell script to react to config changes at runtime.

---

## Components

### 1. `spank` binary
No changes. Existing Go binary at `/usr/local/bin/spank`.

### 2. `spank-supervisor` (new Go binary)
Replaces `spank-wrapper`. Long-running process supervisor that:

- Polls `~/.config/spank/config.json` every second
- Translates config → spank CLI flags
- Launches spank as a child process
- On config change: SIGTERMs the child, waits for exit, relaunches with new flags
- On `enabled: false`: kills child, idles until re-enabled
- Installed at `/usr/local/bin/spank-supervisor`
- LaunchDaemon plist updated to point at supervisor (KeepAlive: true)

**Pack → flags mapping:**

| Config `pack` value | spank flags |
|---|---|
| `"pain"` | (none, default) |
| `"sexy"` | `--sexy` |
| `"halo"` | `--halo` |
| `"nikke/<Name>"` | `--custom ~/spank-sounds/nikke/<Name>/` |
| `"lol/<Name>"` | `--custom ~/spank-sounds/lol/<Name>/` |

**All config flags:**

```json
{
  "enabled": true,
  "pack": "nikke/Privaty",
  "escalate": false,
  "fast": false,
  "volumeScaling": false,
  "sensitivity": 0.25,
  "speed": 1.0,
  "cooldown": 750
}
```

Flags `escalate`, `fast`, `volumeScaling` map to `--escalate`, `--fast`, `--volume-scaling`.
`sensitivity` → `--min-amplitude`, `speed` → `--speed`, `cooldown` → `--cooldown`.

### 3. `SpankBar.app` (Swift/SwiftUI menu bar app)
Native macOS menu bar app in `SpankBar/` Xcode project within the same repo.

- `@main` App struct with `@NSApplicationDelegateAdaptor`
- `NSStatusItem` with SF Symbols icon (`hand.raised.fill` or `waveform`)
- `INFOPLIST_KEY_LSUIElement = YES` (hidden from Dock)
- Reads `~/.config/spank/config.json` on launch and on menu open
- Writes config atomically on any menu selection
- No IPC — purely file-based
- LaunchAgent at `~/Library/LaunchAgents/com.scott.spankbar.plist` for auto-start at login

**Menu structure:**

```
[icon]
✓ Enabled
──────────────
● Privaty          ← checkmark on active pack
  Rapi
  Anis
  Neon
  Alice
  Blanc
  Modernia
  Noir
  Scarlet
  ──────────
  Pain
  Sexy
  Halo
──────────────
✓ Escalation
✓ Fast mode
✓ Volume scaling
──────────────
Sensitivity  ▸  [0.05 / 0.10 / 0.15 / 0.25 / 0.40]
Speed        ▸  [0.5x / 0.75x / 1x / 1.5x / 2x]
Cooldown     ▸  [350ms / 500ms / 750ms / 1000ms]
──────────────
Quit
```

Nikke characters are auto-discovered at runtime by reading `~/spank-sounds/nikke/`. Adding new characters requires no code change.

### 4. Config file
`~/.config/spank/config.json` — user-writable, created with defaults on first run by either the supervisor or SpankBar.

---

## Repo Structure

```
spank-sfwn/
├── main.go                        # spank binary (unchanged)
├── supervisor/
│   └── main.go                    # spank-supervisor binary
├── SpankBar/
│   ├── SpankBar.xcodeproj
│   └── SpankBar/
│       ├── SpankBarApp.swift
│       ├── AppDelegate.swift
│       └── ...
├── audio/
│   ├── pain/
│   ├── sexy/
│   ├── halo/
│   ├── nikke/                     # README + Privaty MP3s copied in
│   └── league/                    # README only for now
├── scripts/
│   └── normalize.sh
└── Makefile
```

---

## Makefile Targets

| Target | Action |
|---|---|
| `make build` | Build spank + spank-supervisor Go binaries |
| `make build-app` | Run `xcodebuild` for SpankBar.app |
| `make install` | Build all, install binaries, prompt for sudo steps |
| `make install-agent` | Install SpankBar LaunchAgent, load it |
| `make normalize` | Run normalize.sh on audio packs |

---

## Install Story

1. `make install` builds spank + spank-supervisor, installs to `/usr/local/bin/`
2. Scott runs `sudo` commands to update the LaunchDaemon plist and reload
3. `make build-app` builds SpankBar.app → copy to `/Applications/`
4. `make install-agent` installs LaunchAgent plist → auto-starts SpankBar at login

---

## Audio Packs

- **Embedded** (compiled in): Pain, Sexy, Halo — no change
- **Nikke** (runtime `--custom`): auto-discovered from `~/spank-sounds/nikke/`
- **Privaty** MP3s (8 clips): already downloaded to `~/spank-sounds/nikke/Privaty/`

---

## Out of Scope

- Embedding Nikke/LoL packs into the binary (use `--custom` at runtime instead)
- LoL pack support in menu (directory exists but no clips downloaded yet)
- Slider UI for sensitivity/speed (submenus with fixed values only)
- Live spank event display in menu bar
