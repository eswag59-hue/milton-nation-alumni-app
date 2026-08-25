#!/bin/bash
# Assemble anthem v2: 60s master + 30s + 15s cutdowns (all 9:16 1080×1920)
set -e
V=/tmp/claude-0/-home-user-milton-nation-alumni-app/dd2da122-5343-58be-9237-b6e112802222/scratchpad/video
FF=$(python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())")
cd "$V/rec"

declare -A DUR=( [seg01]=5.0 [seg02]=4.0 [seg03]=8.0 [seg04]=4.5 [seg05]=7.0
                 [seg06]=6.5 [seg07]=6.0 [seg08]=5.5 [seg09]=6.0 [seg10]=9.0 )

for s in "${!DUR[@]}"; do
  $FF -y -loglevel error -ss 0.10 -i "$s.webm" -t "${DUR[$s]}" \
    -vf "scale=1080:1920:flags=lanczos,fps=25,format=yuv420p" \
    -c:v libx264 -preset medium -crf 17 -an "$s.mp4"
done
echo "segments trimmed"

mux () { # mux <silent.mp4> <score.wav> <out.mp4>
  $FF -y -loglevel error -i "$1" -i "$2" -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart "$3"
}

# ── master (61.5s) ──
> c_master.txt
for s in seg01 seg02 seg03 seg04 seg05 seg06 seg07 seg08 seg09 seg10; do echo "file '$V/rec/$s.mp4'" >> c_master.txt; done
$FF -y -loglevel error -f concat -safe 0 -i c_master.txt -c copy master-silent.mp4
mux master-silent.mp4 "$V/out/score-master.wav" "$V/out/Milton-Nation-Anthem-60s-v2.mp4"

# ── 30s cut: icon → home → counter → community → endcard(7s, fade) ──
$FF -y -loglevel error -i seg10.mp4 -t 7 -vf "fade=t=out:st=6.4:d=0.6" -c:v libx264 -preset medium -crf 17 -an seg10cut.mp4
> c_30.txt
for s in seg02 seg03 seg04 seg05 seg10cut; do echo "file '$V/rec/$s.mp4'" >> c_30.txt; done
$FF -y -loglevel error -f concat -safe 0 -i c_30.txt -c copy cut30-silent.mp4
mux cut30-silent.mp4 "$V/out/score-cut30.wav" "$V/out/Milton-Nation-Anthem-30s-v2.mp4"

# ── 15s cut: icon(3.5s) → counter → endcard(7s) ──
$FF -y -loglevel error -i seg02.mp4 -t 3.5 -c:v libx264 -preset medium -crf 17 -an seg02cut.mp4
> c_15.txt
for s in seg02cut seg04 seg10cut; do echo "file '$V/rec/$s.mp4'" >> c_15.txt; done
$FF -y -loglevel error -f concat -safe 0 -i c_15.txt -c copy cut15-silent.mp4
mux cut15-silent.mp4 "$V/out/score-cut15.wav" "$V/out/Milton-Nation-Anthem-15s-v2.mp4"

ls -la "$V/out/" | grep "v2.mp4"
