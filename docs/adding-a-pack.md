# Adding a Sound Pack

## 1. Add audio files

Place normalized MP3s in `audio/<packname>/`. Run:

```bash
make normalize
```

## 2. Add embed directive in `main.go`

```go
//go:embed audio/<packname>/*.mp3
var <packname>Audio embed.FS
```

## 3. Add flag variable

```go
<packname>Mode bool
```

And in the `var (...)` block, add it alongside `sexyMode`, `haloMode`.

## 4. Register the flag

In `main()`, alongside the other flag registrations:

```go
cmd.Flags().BoolVarP(&<packname>Mode, "<packname>", "", false, "Enable <packname> mode")
```

## 5. Add case to `run()`

In the `modeCount` block:
```go
if <packname>Mode {
    modeCount++
}
```

In the `switch` block:
```go
case <packname>Mode:
    pack = &soundPack{name: "<packname>", fs: <packname>Audio, dir: "audio/<packname>", mode: modeRandom}
```

## Escalation vs Random

New packs default to `modeRandom`. The `--escalate` flag (planned) will override any pack to
use `modeEscalation` at runtime, so no separate flag is needed per pack.

## Naming files for escalation

If a pack will ever be used in escalation mode, name files numerically so they sort
from least to most intense:

```
01_mild.mp3
02_medium.mp3
03_intense.mp3
```

`modeRandom` ignores ordering entirely.
