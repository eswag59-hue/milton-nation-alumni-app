#!/usr/bin/env bash
# Assembles the 60-second launch film from ten Higgsfield shots + the type set.
#
#   src/assemble60.sh <shots-dir> <out.mp4>
#
# <shots-dir> must contain S01.mp4 … S10.mp4. Type cards come from ../build/
# (run make_titles.py first). Timings mirror SHOTLIST-60S.md exactly.
#
# Each shot is trimmed to its slot and cross-dissolved into the next, so the
# film is continuous — no hard cuts except the one into the end card, which is
# deliberate.
set -euo pipefail
FF="$(python3 -c 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())')"
SHOTS="${1:?usage: assemble60.sh <shots-dir> <out.mp4>}"
OUT="${2:?usage: assemble60.sh <shots-dir> <out.mp4>}"
cd "$(dirname "$0")"
B=../build
T=$B/tmp60
mkdir -p "$T"

W=1080; H=1920; FPS=30; XF=0.6      # cross-dissolve length

# Slot lengths in seconds. With nine 0.6s cross-dissolves these sum to a 56.0s
# spine; + a 4.0s end card = exactly 60.0. The groupings match the act
# boundaries in SHOTLIST-60S.md: I 12s, II 10s, III 18s, IV 8s, V 8s.
#      S01  S02  S03  S04  S05  S06  S07  S08  S09  S10
LENS=( 6.6  6.6  5.6  5.6  6.6  6.6  6.6  4.6  4.6  8.0 )

# Higgsfield returns ~6.6s clips, so S10's 8.6s slot is filled by slowing it to
# 0.77x. A slow-motion pull-back is the right feel for the final shot anyway —
# this is a deliberate choice, not padding.
SLOW_S10=0.77

echo "→ normalising ten shots to ${W}x${H}@${FPS}"
for i in $(seq 1 10); do
  n=$(printf "S%02d" "$i"); len=${LENS[$((i-1))]}
  [ -f "$SHOTS/$n.mp4" ] || { echo "missing $SHOTS/$n.mp4"; exit 1; }
  SPEED=""
  [ "$n" = "S10" ] && SPEED="setpts=PTS/$SLOW_S10,"
  "$FF" -y -loglevel error -i "$SHOTS/$n.mp4" \
    -vf "${SPEED}scale=$W:$H:force_original_aspect_ratio=increase,crop=$W:$H,fps=$FPS,setsar=1,format=yuv420p" \
    -t "$len" -an -c:v libx264 -crf 17 -preset medium "$T/$n.mp4"
done

echo "→ cross-dissolving into one continuous 60s"
# Chain xfade: each offset is (running total of previous slots) - (XF per join).
CUR="$T/S01.mp4"; ACC=${LENS[0]}
for i in $(seq 2 10); do
  n=$(printf "S%02d" "$i"); OFF=$(python3 -c "print(round($ACC-$XF,3))")
  "$FF" -y -loglevel error -i "$CUR" -i "$T/$n.mp4" \
    -filter_complex "[0:v][1:v]xfade=transition=fade:duration=$XF:offset=$OFF,format=yuv420p[v]" \
    -map "[v]" -c:v libx264 -crf 17 -preset medium "$T/chain$i.mp4"
  CUR="$T/chain$i.mp4"
  ACC=$(python3 -c "print(round($ACC+${LENS[$((i-1))]}-$XF,3))")
done
echo "   spine length: ${ACC}s"

# Type cards. in/out are absolute seconds on the finished timeline.
#          file                          in    out
CARDS=(
  "type-01-day-one.png                   9.0   13.0"
  "type-02-not-alone.png                19.0   23.0"
  "type-03a-community.png               29.0   31.6"
  "type-03b-careteam.png                31.8   34.4"
  "type-03c-meeting.png                 34.6   37.6"
  "type-04-counted.png                  41.0   46.6"
  "type-05-days.png                     45.2   50.0"
)
echo "→ overlaying ${#CARDS[@]} type cards"
# One ffmpeg pass per card rather than one graph with seven looped inputs.
# Seven 1080x1920 RGBA PNGs each looped to 56s at 30fps is ~7x1680 uncompressed
# frames held at once, which the OOM killer ends. Sequential passes keep memory
# flat; intermediates use a fast preset since only the final pass sets quality.
STEP="$CUR"; k=0
for spec in "${CARDS[@]}"; do
  read -r f tin tout <<<"$spec"
  fin=$(python3 -c "print(round($tin-0.5,3))")
  # -loop 1 is load-bearing: a single-frame PNG gives the fade no frames to act
  # on, so the card silently never appears.
  "$FF" -y -loglevel error -i "$STEP" -loop 1 -framerate $FPS -t "$ACC" -i "$B/$f" \
    -filter_complex "[1:v]format=rgba,fade=t=in:st=$fin:d=0.5:alpha=1,\
fade=t=out:st=$tout:d=0.6:alpha=1[c];[0:v][c]overlay=0:0:format=auto:shortest=1[v]" \
    -map "[v]" -c:v libx264 -crf 20 -preset veryfast "$T/ov$k.mp4"
  STEP="$T/ov$k.mp4"; k=$((k+1))
done
"$FF" -y -loglevel error -i "$STEP" -vf "fade=t=in:st=0:d=1.0" \
  -c:v libx264 -crf 17 -preset medium "$T/spine.mp4"

# End card: 4s, slow push, hard cut in from the spine.
"$FF" -y -loglevel error -loop 1 -framerate $FPS -t 4.0 -i "$B/endcard.png" \
  -filter_complex "scale=2160:3840,\
zoompan=z='1+0.030*on/119':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=${W}x${H}:fps=$FPS,\
setsar=1,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=3.4:d=0.6" \
  -c:v libx264 -crf 17 -preset medium "$T/end.mp4"

printf "file 'spine.mp4'\nfile 'end.mp4'\n" > "$T/concat.txt"
"$FF" -y -loglevel error -f concat -safe 0 -i "$T/concat.txt" -c copy "$OUT"

echo "→ cutdowns"
"$FF" -y -loglevel error -i "$OUT" -vf "crop=1080:1080:0:420,setsar=1" \
  -c:v libx264 -crf 18 -preset medium "${OUT%.mp4}-1x1.mp4"
"$FF" -y -loglevel error -i "$OUT" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,\
pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=#080E12,setsar=1" \
  -c:v libx264 -crf 18 -preset medium "${OUT%.mp4}-16x9.mp4"

echo
echo "built:"
for f in "$OUT" "${OUT%.mp4}-1x1.mp4" "${OUT%.mp4}-16x9.mp4"; do
  printf "  %-42s %s\n" "$f" "$("$FF" -hide_banner -i "$f" 2>&1 | sed -n 's/.*Duration: \([0-9:.]*\),.*/\1/p')"
done
