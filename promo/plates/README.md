# Studio plates

Generated with Higgsfield `cinematic_studio_2_5` — exact prompts in `../prompts.md`.
Stored as quality-90 JPEG (they are used as backgrounds; the PNG originals were ~5 MB each).

`film.py` reads `plates/*.png` by default. Either regenerate the PNGs from `prompts.md`
or point `PLATE` at these `.jpg` files.

## Not committed: `ui/`

The renderer also needs `ui/` — the app screenshots with status bars stripped
(`<4-digit IMG id>.png`, 1170×2352). These are **deliberately not in the repo**: they are
captures of care-team chat threads, member profiles and phone numbers. Demo data, but
screenshots of that shape do not belong in version control on a HIPAA-aware project.

Rebuild them from a screenshot set with:

```python
from PIL import Image
import os
os.makedirs('ui', exist_ok=True)
for f in sorted(os.listdir('screenshots')):
    if f.endswith('.PNG'):
        im = Image.open(f'screenshots/{f}').convert('RGB')
        im.crop((0, 180, im.width, im.height)).save(f'ui/{f[4:8]}.png')  # strip status bar
```

The current cut references: `0316` `0323` `0327` `0349` `0355` `0357`.
