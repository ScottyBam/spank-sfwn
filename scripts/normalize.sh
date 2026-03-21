#!/usr/bin/env bash
# normalize.sh — Normalizes all MP3 files in audio/ subdirectories to -16 LUFS.
#
# Requires ffmpeg: brew install ffmpeg
#
# Usage:
#   ./scripts/normalize.sh              # normalize all packs
#   ./scripts/normalize.sh audio/nikke  # normalize a specific pack

set -euo pipefail

TARGET_LUFS=-16
TARGET_LRA=11
TARGET_TP=-1.5

if ! command -v ffmpeg &>/dev/null; then
    echo "error: ffmpeg not found. Install with: brew install ffmpeg" >&2
    exit 1
fi

normalize_dir() {
    local dir="$1"
    local count=0
    local skipped=0

    echo "→ Normalizing $dir"

    while IFS= read -r -d '' file; do
        local tmp="${file%.mp3}_normalized_tmp.mp3"

        ffmpeg -y -loglevel error \
            -i "$file" \
            -af "loudnorm=I=${TARGET_LUFS}:LRA=${TARGET_LRA}:TP=${TARGET_TP}" \
            "$tmp"

        mv "$tmp" "$file"
        echo "  ✓ $(basename "$file")"
        ((count++))
    done < <(find "$dir" -maxdepth 1 -name "*.mp3" -print0 | sort -z)

    if [[ $count -eq 0 ]]; then
        echo "  (no MP3 files found)"
    else
        echo "  $count file(s) normalized"
    fi
}

if [[ $# -gt 0 ]]; then
    for dir in "$@"; do
        normalize_dir "$dir"
    done
else
    # Normalize all packs
    for dir in audio/*/; do
        if compgen -G "${dir}*.mp3" > /dev/null 2>&1; then
            normalize_dir "$dir"
        fi
    done
fi

echo "Done."
