#!/usr/bin/env bash
# Assembles the launch ad: Higgsfield hero clip + headline + end card.
#
#   ./assemble.sh <hero-clip.mp4> <out.mp4>
#
# Expects ../build/title.png and ../build/endcard.png (make_titles.py).
set -euo pipefail
FF="$(python3 -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')"
CLIP="${1:?usage: assemble.sh <hero-clip.mp4> <out.mp4>}"
OUT="${2:?usage: assemble.sh <hero-clip.mp4> <out.mp4>}"
cd "$(dirname "$0")"
B=../build
mkdir -p "$B"

DUR=$("$FF" -hide_banner -i "$CLIP" 2>&1 | sed -n 's/.*Duration: \([0-9:.]*\).*/\1/p' \
      | awk -F: '{printf "%.2f", $1*3600+$2*60+$3}')

# 1. Hero clip normalised to 1080x1920/30fps, headline fading in over the top
#    negative space. The PNG needs -loop 1: a single-frame input produces one
#    frame at t=0, so a fade scheduled at st=1.1 would never fire and the title
#    would silently never appear.
"$FF" -y -loglevel error \
  -i "$CLIP" \
  -loop 1 -framerate 30 -t "$DUR" -i "$B/title.png" \
  -filter_complex "\
    [0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,setsar=1[v]; \
    [1:v]format=rgba,fade=t=in:st=1.1:d=0.9:alpha=1,fade=t=out:st=4.6:d=0.8:alpha=1[t]; \
    [v][t]overlay=0:0:format=auto:shortest=1,fade=t=in:st=0:d=0.5[seg1]" \
  -map "[seg1]" -c:v libx264 -pix_fmt yuv420p -crf 17 -preset medium "$B/seg1.mp4"

# 2. End card, 3s, with a slow push so it never reads as a frozen JPEG.
#    zoompan expands each INPUT frame into d output frames, so d must be 1 and
#    the input must already run at the output rate — otherwise 3s becomes 3m45s.
"$FF" -y -loglevel error -loop 1 -framerate 30 -t 3.0 -i "$B/endcard.png" \
  -filter_complex "\
    scale=2160:3840,\
zoompan=z='1+0.030*on/89':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920:fps=30,\
setsar=1,fade=t=in:st=0:d=0.6,fade=t=out:st=2.4:d=0.6" \
  -c:v libx264 -pix_fmt yuv420p -crf 17 -preset medium "$B/seg2.mp4"

# 3. Join, then cut the 1:1 feed version off the master.
printf "file 'seg1.mp4'\nfile 'seg2.mp4'\n" > "$B/concat.txt"
"$FF" -y -loglevel error -f concat -safe 0 -i "$B/concat.txt" -c copy "$OUT"
"$FF" -y -loglevel error -i "$OUT" -vf "crop=1080:1080:0:420,setsar=1" \
  -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium "${OUT%.mp4}-1x1.mp4"

echo "built: $OUT  and  ${OUT%.mp4}-1x1.mp4"
"$FF" -hide_banner -i "$OUT" 2>&1 | grep -E "Duration|Stream #0:0"
