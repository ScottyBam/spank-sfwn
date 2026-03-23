<p align="center">
  <img src="doc/logo.png" alt="spank logo" width="200">
</p>

# spank

**English** | [简体中文][readme-zh-link]

Slap your MacBook, it yells back.

> "this is the most amazing thing i've ever seen" — [@kenwheeler](https://x.com/kenwheeler)

> "I just ran sexy mode with my wife sitting next to me...We died laughing" — [@duncanthedev](https://x.com/duncanthedev)

> "peak engineering" — [@tylertaewook](https://x.com/tylertaewook)

Uses the Apple Silicon accelerometer (Bosch BMI286 IMU via IOKit HID) to detect physical hits on your laptop and plays audio responses. Single binary, no dependencies.

---

## sfwn fork — SpankBar + Supervisor

This fork adds two components on top of the original spank binary:

- **spank-supervisor** — a Go daemon that watches `~/.config/spank/config.json` and automatically restarts spank when settings change. Runs as a system LaunchDaemon (root).
- **SpankBar** — a macOS menu bar app (Swift/AppKit) that lets you switch sound packs, toggle modes, and adjust sensitivity without touching the terminal.

### Prerequisites

- macOS on Apple Silicon (M1 or later — M1 Pro confirmed working)
- Go 1.21+ — `brew install go`
- Xcode 15+ — for building SpankBar
- `ffmpeg` (optional) — `brew install ffmpeg`, used by the normalize script
- Sound packs in `~/spank-sounds/` — see [Sound packs](#sound-packs) below

### Install

**Step 1 — Install Go binaries and load the daemon**

```bash
git clone https://github.com/ScottyBam/spank-sfwn
cd spank-sfwn
sudo bash scripts/install.sh
```

This builds `spank` and `spank-supervisor`, installs them to `/usr/local/bin`, signs them, writes the LaunchDaemon plist with your home directory, and starts the daemon. The daemon runs at boot automatically.

**Step 2 — Build SpankBar**

Open Xcode:
```bash
open SpankBar/SpankBar.xcodeproj
```

Press **⌘B** to build. When complete: **Product → Show Build Folder in Finder**, navigate to `Release/`, and drag `SpankBar.app` to `/Applications`.

**Step 3 — Install the SpankBar LaunchAgent (auto-start at login)**

```bash
make install-agent
```

SpankBar will now launch automatically at login and appear as a ✋ icon in the menu bar.

### Using SpankBar

Click the ✋ icon in the menu bar to open the control panel:

| Control | What it does |
|---|---|
| **Enabled** | Toggles slap detection on/off |
| Nikke characters | Switch to a custom Nikke voice line pack |
| **Pain / Sexy / Halo** | Switch to a built-in pack |
| **Escalation** | Force intensity-based escalation on any pack |
| **Fast mode** | Short cooldown, higher sensitivity preset |
| **Volume scaling** | Louder on harder hits |
| **Sensitivity** | Detection threshold (lower = more sensitive) |
| **Speed** | Playback speed multiplier |
| **Cooldown** | Minimum time between responses |

Changes take effect immediately — the supervisor restarts spank with the new settings within one second.

### Sound packs

Custom sound packs live under `~/spank-sounds/<category>/<CharacterName>/`. Each category gets its own submenu in SpankBar. New categories and characters are discovered automatically — no config needed.

```
~/spank-sounds/
├── nikke/
│   ├── Privaty/
│   │   ├── 01.mp3
│   │   └── 02.mp3
│   └── Rapi/
├── lol/
│   ├── Ahri/
│   └── Jinx/
└── overwatch/
    └── D_Va/
```

Known categories have friendly display names in the menu (`lol` → **League of Legends**, `nikke` → **Nikke**, `overwatch` → **Overwatch**). Any other folder name is title-cased automatically.

If you're interested in getting sounds set up, drop me a message.

### Updating after code changes

```bash
# Rebuild and redeploy Go binaries + restart daemon
sudo bash scripts/install.sh

# SpankBar only (after Xcode build)
sudo cp -R /tmp/SpankBarBuild/Build/Products/Release/SpankBar.app /Applications/
make install-agent
```

### Logs

```bash
tail -f /tmp/spank.log   # detection events (slap #N, amplitude, file played)
tail -f /tmp/spank.err   # supervisor restarts and errors
```

---

## Requirements

- macOS on Apple Silicon (M1 or later)
- `sudo` (for IOKit HID accelerometer access)
- Go 1.21+ (if building from source)

## Install

Download from the [latest release](https://github.com/taigrr/spank/releases/latest).

Or build from source:

```bash
go install github.com/taigrr/spank@latest
```

> **Note:** `go install` places the binary in `$GOBIN` (if set) or `$(go env GOPATH)/bin` (which defaults to `~/go/bin`). Copy it to a system path so `sudo spank` works. For example, with the default Go settings:
>
> ```bash
> sudo cp "$(go env GOPATH)/bin/spank" /usr/local/bin/spank
> ```

## Usage

```bash
# Normal mode — says "ow!" when slapped
sudo spank

# Sexy mode — escalating responses based on slap frequency
sudo spank --sexy

# Halo mode — plays Halo death sounds when slapped
sudo spank --halo

# Fast mode — faster polling and shorter cooldown
sudo spank --fast
sudo spank --sexy --fast

# Escalate mode — force escalation (intensity-based) on any pack
sudo spank --halo --escalate
sudo spank --custom /path/to/mp3s --escalate

# Custom mode — plays your own MP3 files from a directory
sudo spank --custom /path/to/mp3s

# Adjust sensitivity with amplitude threshold (lower = more sensitive)
sudo spank --min-amplitude 0.1   # more sensitive
sudo spank --min-amplitude 0.25  # less sensitive
sudo spank --sexy --min-amplitude 0.2

# Set cooldown period in millisecond (default: 750)
sudo spank --cooldown 600

# Set playback speed multiplier (default: 1.0)
sudo spank --speed 0.7   # slower and deeper
sudo spank --speed 1.5   # faster
sudo spank --sexy --speed 0.6
```

### Modes

**Pain mode** (default): Randomly plays from 10 pain/protest audio clips when a slap is detected.

**Sexy mode** (`--sexy`): Tracks slaps within a rolling 5-minute window. The more you slap, the more intense the audio response. 60 levels of escalation.

**Halo mode** (`--halo`): Randomly plays from death sound effects from the Halo video game series when a slap is detected.

**Custom mode** (`--custom`): Randomly plays MP3 files from a custom directory you specify.

**Nikke mode** (`--nikke`): *(coming soon)* Voice lines from Nikke: Goddess of Victory.

**League of Legends mode** (`--league`): *(coming soon)* Champion voice lines from League of Legends.

### Escalation mode

Pass `--escalate` alongside any pack flag to override random playback with intensity-based escalation — the more frequently you slap, the further through the file list it progresses. Files should be named numerically (`01_mild.mp3`, `02_medium.mp3` etc.) for the ordering to make sense.

`--sexy` uses escalation by default. All other packs default to random.

### Detection tuning

Use `--fast` for a more responsive profile with faster polling (4ms vs 10ms), shorter cooldown (350ms vs 750ms), higher sensitivity (0.18 vs 0.05 threshold), and larger sample batch (320 vs 200).

You can still override individual values with `--min-amplitude` and `--cooldown` when needed.

### Sensitivity

Control detection sensitivity with `--min-amplitude` (default: `0.05`):

- Lower values (e.g., 0.05-0.10): Very sensitive, detects light taps
- Medium values (e.g., 0.15-0.30): Balanced sensitivity
- Higher values (e.g., 0.30-0.50): Only strong impacts trigger sounds

The value represents the minimum acceleration amplitude (in g-force) required to trigger a sound.

## Running as a Service

To have spank start automatically at boot, create a launchd plist. Pick your mode:

<details>
<summary>Pain mode (default)</summary>

```bash
sudo tee /Library/LaunchDaemons/com.taigrr.spank.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.taigrr.spank</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/spank</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/spank.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/spank.err</string>
</dict>
</plist>
EOF
```

</details>

<details>
<summary>Sexy mode</summary>

```bash
sudo tee /Library/LaunchDaemons/com.taigrr.spank.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.taigrr.spank</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/spank</string>
        <string>--sexy</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/spank.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/spank.err</string>
</dict>
</plist>
EOF
```

</details>

<details>
<summary>Halo mode</summary>

```bash
sudo tee /Library/LaunchDaemons/com.taigrr.spank.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.taigrr.spank</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/spank</string>
        <string>--halo</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/spank.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/spank.err</string>
</dict>
</plist>
EOF
```

</details>

> **Note:** Update the path to `spank` if you installed it elsewhere (e.g. `~/go/bin/spank`).

Load and start the service:

```bash
sudo launchctl load /Library/LaunchDaemons/com.taigrr.spank.plist
```

Since the plist lives in `/Library/LaunchDaemons` and no `UserName` key is set, launchd runs it as root — no `sudo` needed.

To stop or unload:

```bash
sudo launchctl unload /Library/LaunchDaemons/com.taigrr.spank.plist
```

## How it works

1. Reads raw accelerometer data directly via IOKit HID (Apple SPU sensor)
2. Runs vibration detection (STA/LTA, CUSUM, kurtosis, peak/MAD)
3. When a significant impact is detected, plays an embedded MP3 response
4. **Optional volume scaling** (`--volume-scaling`) — light taps play quietly, hard slaps play at full volume
5. **Optional speed control** (`--speed`) — adjusts playback speed and pitch (0.5 = half speed, 2.0 = double speed)
6. 750ms cooldown between responses to prevent rapid-fire, adjustable with `--cooldown`

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=taigrr/spank&type=date&legend=top-left)](https://www.star-history.com/#taigrr/spank&type=date&legend=top-left)

## Credits

Sensor reading and vibration detection ported from [olvvier/apple-silicon-accelerometer](https://github.com/olvvier/apple-silicon-accelerometer).

## License

MIT

<!-- Links -->
[readme-zh-link]: ./README-zh.md
