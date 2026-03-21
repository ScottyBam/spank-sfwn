# League of Legends Audio Pack

Place MP3 champion voice line clips here.

## Sourcing

Champion voice lines can be extracted from the League of Legends client using:
- [Obsidian (LoL data extraction tool)](https://github.com/Crauzer/Obsidian) — extracts `.wem` audio from `.wad` files
- Convert `.wem` to WAV using [vgmstream](https://github.com/vgmstream/vgmstream)

Then convert to MP3 and normalize:
```bash
ffmpeg -i input.wem -q:a 2 output.mp3
make normalize
```

## Naming

Files can be named anything — playback is random by default.
For escalation mode ordering, name them `01_name.mp3`, `02_name.mp3` etc.
