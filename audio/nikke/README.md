# Nikke Audio Pack

Place MP3 voice line clips here.

## Sourcing

Voice lines can be extracted from Nikke: Goddess of Victory game files using community tools such as:
- [UABE (Unity Asset Bundle Extractor)](https://github.com/SeriousCache/UABE)
- [AssetStudio](https://github.com/Perfare/AssetStudio)

Export as WAV, convert to MP3:
```bash
ffmpeg -i input.wav -q:a 2 output.mp3
```

Then run normalization from the repo root:
```bash
make normalize
```

## Naming

Files can be named anything — playback is random by default.
For escalation mode ordering, name them `01_name.mp3`, `02_name.mp3` etc.
