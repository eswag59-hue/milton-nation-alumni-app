#!/usr/bin/env bash
# Bodoni Moda echoes the milton wordmark's high-contrast didone; Jost carries
# the utility line. Pulled from gstatic — github raw is blocked by the proxy.
set -euo pipefail
cd "$(dirname "$0")"; mkdir -p fonts
CSS=$(curl -sS -A "Mozilla/5.0" \
  "https://fonts.googleapis.com/css2?family=Bodoni+Moda:wght@400;600&family=Jost:wght@300;400;500&display=swap")
curl -sS -o fonts/BodoniModa.ttf "$(echo "$CSS" | grep -oE 'https://fonts.gstatic.com/s/bodonimoda/[^)]+' | head -1)"
curl -sS -o fonts/Jost.ttf       "$(echo "$CSS" | grep -oE 'https://fonts.gstatic.com/s/jost/[^)]+'       | head -1)"
python3 -c "
from PIL import ImageFont
for f in ('fonts/BodoniModa.ttf','fonts/Jost.ttf'):
    print(f, '->', ImageFont.truetype(f, 40).getname())"
