# Studio plate prompts (Higgsfield)

Model: `cinematic_studio_2_5`, `resolution: 2k`. Generate 16:9 and 9:16 variants of each.

Every prompt ends with the same negative clause — the plates must stay empty so real UI
composites in cleanly:

> Absolutely no text, no logos, no user interface, no people, no hands.

## Palette lock
`#101820` ink · `#165C7D` deep teal · `#007396` signature · `#0093B2` cyan ·
`#369DA0` teal · `#56B093` sage · `#D4EB8E` lime

## bg16 / bg9 — the workhorse (used by most beats)
> Ultra-photorealistic EMPTY studio background plate. An infinite pitch-black cyclorama above a polished dark obsidian floor. A deep teal-cyan volumetric light beam rakes diagonally from the upper right through fine atmospheric haze, blooming softly in the middle of the frame and falling off into total darkness at every edge. Subtle soft reflection of the glow on the floor. The scene is COMPLETELY EMPTY — no objects, no products, no phone, no furniture, no people, no text, nothing in frame but light, haze and floor. ARRI Alexa, 50mm, T2, cinematic grade, deep blacks, teal and cyan only, enormous negative space. 8K.

## t1 — hero beauty shot (16:9 title beat only)
> Ultra-photorealistic product film still. A single modern smartphone with a black anodised titanium frame floats perfectly vertical, centred, in an infinite pitch-black studio void. Shot PERFECTLY FRONT-ON: the screen plane exactly parallel to the camera sensor, zero perspective distortion, perfectly symmetrical. Screen completely OFF — pure black glass, no interface, no icons, no text anywhere. One large softbox from upper left rakes a razor-thin specular highlight down the machined chamfered edge. Behind and to the right a deep teal-cyan volumetric light beam cuts through fine atmospheric haze, wrapping a cool rim around the phone's right edge. Faint reflection on a polished obsidian floor below. ARRI Alexa, 100mm macro, T1.4, extremely shallow depth of field, cinematic grade, deep blacks, teal and cyan accents only.

**Note:** the model does not reliably honour "front-on" — the delivered plate carries ~10°
of Y-rotation, so a flat screenshot cannot be pasted onto it. It is used as a *beauty
shot with the screen off*; every UI beat uses the natively-drawn device instead
(`engine.device()`), which stays pixel-crisp at any scale.

## t4 — frosted glass panes (privacy beat)
> Ultra-photorealistic abstract studio still. Four large rectangular panes of frosted glass float at slight staggered angles in an infinite pitch-black void, arranged in receding depth like weightless cards. Each pane is blank, empty, featureless frosted glass — no text, no images, no interface, nothing printed on them. Deep teal and cyan volumetric light passes through the glass, throwing soft refractive caustics and coloured edge-glow along the polished bevels. Fine atmospheric haze, visible light shafts. ARRI Alexa, 100mm, T1.4, extremely shallow depth of field so the nearest pane is razor sharp and the furthest dissolves into darkness.

## wide16 / wide9 — pulled-back plate (spare end-card option)
> Ultra-photorealistic product film still, WIDE. A single modern smartphone with a black anodised titanium frame floats perfectly vertical and small in the lower third of an enormous infinite pitch-black studio void, leaving vast empty negative space above and around it. Shot PERFECTLY FRONT-ON. Screen completely OFF. A soft wide teal-cyan glow blooms low behind the phone and falls off into total darkness toward the top of the frame. Gentle atmospheric haze, faint polished floor reflection. ARRI Alexa, 50mm, T2.

## hand16 / hand9 — anonymous human presence (unused in the current cut; held in reserve)
> Ultra-photorealistic cinematic still. An anonymous adult hand, seen from behind and above over the shoulder, loosely holds a modern black smartphone down at their side in a very dark room. NO FACE VISIBLE, no head in frame, no identifying features, plain dark long sleeve. The phone screen is OFF, dark. A single cool teal-cyan light source far off to the right rims the knuckles and the phone's edge; everything else falls into deep shadow. ARRI Alexa, 85mm, T1.4, quiet and dignified mood.

## Not available in Higgsfield
`generate_audio` is speech-only; the music and SFX models are locked to the game pipeline
and must not be used for standalone audio. The score has to be licensed
(Artlist / Musicbed / Epidemic Sound) — search *"minimal piano swell cinematic hopeful 60s"*.
