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
- Detects changes via SHA-256 hash of the config file contents (not mtime) — avoids spurious restarts when SpankBar writes identical values
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
| `"nikke/<Name>"` | `--custom /Users/scott/spank-sounds/nikke/<Name>/` |

**All config flags:**

```json
{
  "enabled": true,
  "pack": "nikke/Privaty",
  "escalate": false,
  "fast": false,
  "volumeScaling": false,
  "sensitivity": 0.05,
  "speed": 1.0,
  "cooldown": 750
}
```

Flags `escalate`, `fast`, `volumeScaling` map to `--escalate`, `--fast`, `--volume-scaling`.
`sensitivity` → `--min-amplitude`, `speed` → `--speed`, `cooldown` → `--cooldown`.

**Path expansion:** The supervisor runs as root and must expand the user home directory explicitly (e.g. `/Users/scott/`) — `~` is not expanded by `exec` when called from Go.

**`--stdio` mode:** The supervisor does NOT use `--stdio`. It manages spank purely as a child process (stdout/stderr forwarded to log). Crash detection is via process exit, not JSON events.

**Idle behaviour:** When `enabled: false`, the supervisor kills the child and enters a poll loop — it never exits, because launchd would immediately restart it.

**Crash recovery:** If the spank child exits unexpectedly while `enabled: true` (e.g. IOKit error), the supervisor waits 1 second and relaunches it automatically.

### 3. `SpankBar.app` (Swift/SwiftUI menu bar app)
Native macOS menu bar app in `SpankBar/` Xcode project within the same repo.

- `@main` App struct with `@NSApplicationDelegateAdaptor`
- `NSStatusItem` with SF Symbols icon (`hand.raised.fill` or `waveform`)
- `INFOPLIST_KEY_LSUIElement = YES` (hidden from Dock)
- Reads `~/.config/spank/config.json` on launch and on menu open
- Writes config atomically (temp file + rename) on any menu selection
- No IPC — purely file-based
- LaunchAgent at `~/Library/LaunchAgents/com.scott.spankbar.plist` for auto-start at login
- If the config file does not exist on launch, SpankBar polls every 500ms until it appears (up to 10 seconds); if still absent, shows menu greyed out with "Waiting for daemon…" and continues polling. Menu becomes active once the file appears.

**Menu structure:**

```
[icon]
✓ Enabled
──────────────
● Privaty          ← example: checkmark on active pack (list is dynamic)
  Rapi
  Anis
  ...              ← all subdirs of ~/spank-sounds/nikke/, sorted alphabetically
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

Nikke characters are **auto-discovered at runtime** by reading `~/spank-sounds/nikke/` on each menu open. The list above is example output only — all subdirectories are shown, sorted alphabetically. Adding new characters requires no code change.

All MP3 clips for a character (including costume variants) reside flat in a single directory (e.g. `Privaty/Privaty_Damaged_1.mp3`, `Privaty/Privaty_(Sharp_Lesson)_Death.mp3`). No sub-subdirectories exist; the `--custom` path points directly at the character directory.

SpankBar does not use `--custom-files`; `--custom <dir>` only.

### 4. Config file
`~/.config/spank/config.json` — user-writable. On first run the supervisor creates the `~/.config/spank/` directory if absent, then writes the config atomically (temp file + rename). SpankBar reads it but will not create it; if missing on launch, SpankBar polls until it appears.

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
- LoL pack support in menu (directory exists but no clips downloaded yet; not in supervisor flag table)
- Slider UI for sensitivity/speed (submenus with fixed values only)
- Live spank event display in menu bar
- `--stdio` integration (supervisor manages spank as a plain child process only)
