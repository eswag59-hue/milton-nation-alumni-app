#!/usr/bin/env bash
# Mux the rendered frames with the 52s score.
set -euo pipefail
cd "$(dirname "$0")/.."
FF=$(python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())")
"$FF" -y -framerate 30 -i src/full/frames_film3/f%04d.jpg -i build/score.m4a \
  -map 0:v -map 1:a -shortest \
  -c:v libx264 -preset slow -crf 19 -pix_fmt yuv420p \
  -profile:v high -level 4.2 -movflags +faststart \
  -c:a aac -b:a 192k \
  assets/milton-hero.mp4
"$FF" -y -i assets/milton-hero.mp4 -vf "scale=540:-2" -an -c:v libx264 -crf 28 \
  -pix_fmt yuv420p build/_preview.mp4
ls -la assets/milton-hero.mp4
"$FF" -i assets/milton-hero.mp4 2>&1 | grep -E "Duration|Stream"
