# Spokesperson launch videos — Ohio + Florida

Two 30-second vertical talking-head videos announcing **Milton Nation Alumni**,
one per state. Built to render correctly on the first attempt.

Engine: Higgsfield `ugc-review-video` pipeline.
Speech is generated **natively by the video model** — see "Do not use ElevenLabs" below.

---

## 0. Read this before you spend anything

**A 30-second talking-head render costs ~210 credits. Two cost ~421.**

| | |
|---|---|
| UGC talking, generated character | 4.5 fixed + 6.87/second |
| One 30s video | 4.5 + (6.87 x 30) = **210.6 credits** |
| Two 30s videos | **421.2 credits** |

Check your balance before starting. If it is short, the options are a top-up, or
the reduced-length fallback in section 8 — not a cheaper model, because the
locked models in this pipeline cannot be substituted without losing the native
lip-synced audio.

---

## 1. Three decisions that make or break the first try

### 1.1 Do not use ElevenLabs or VAPI

The video model (`seedance_2_5`, `mode: omni_reference`, `generate_audio: true`)
generates the speech itself, lip-synced to the face it is rendering.

Bolting on external TTS afterwards is the single most common reason AI
spokesperson videos read as fake: the audio is fine, the mouth is fine, and they
drift a few frames apart. Viewers cannot name it, but they see it.

Let the model speak. It is also cheaper and one less step.

### 1.2 The script must be about 64 words, not 135

Speech density for this pipeline is fixed:

| Clip length | Word budget |
|---|---|
| <= 10s | 12–20 words |
| 11–12s | 20–28 words |
| 13–15s | **28–35 words** |

A 30s video is rendered as **two 15-second clips**, so the total spoken budget is
**56–70 words**.

The dictated version of this script is about 135 words. At that length the model
either races through it or drops the end. The scripts in section 3 are cut to
fit — 57 words for Ohio, 56 for Florida — while keeping every feature.

### 1.3 "Hey guys" is a banned opener

The pipeline's own anti-slop rules ban these as the literal first words:
`Hey guys`, `Okay so`, `OMG`, `So basically`, `Stop scrolling`, `You NEED this`,
`Story time`, and any warmup word (`Okay`, `Alright`, `So`, `Um`, `Well`, `Wait`).

Also banned anywhere in the line: *literally*, *obsessed*, *game-changer*,
*holy grail*, *changed my life*, *hits different*, and corporate register
(*elevate*, *seamless*, *effortless*).

Repeats — "amazing, amazing, amazing" — spend word budget and carry no
information. They are the first thing to cut.

---

## 2. The truth constraint (this one is not optional)

This is healthcare marketing with a generated presenter, so:

**The presenter is a Milton Recovery team member announcing an app. They are not
an alumnus, and they never claim recovery experience of their own.**

The dictated script already gets this right ("I'm here with Milton Recovery") and
the scripts below keep it. A generated person saying "I got sober here" would be
a fabricated testimonial — an ethical problem, a regulatory problem, and a
violation of the pipeline's safety gate that will stop the render.

### Approved claims allowlist

Every claim below is verified against the codebase. Nothing outside this list
goes in the script.

| Claim | Verified in |
|---|---|
| Peer community for alumni | `CommunityScreen`, `CommunityViewModel` |
| Secure chat with your care team | `ChatListScreen`, `ChatDetailScreen` |
| Local AA and NA meeting finder | BMLT public API, `NearbyMeetings` |
| Alumni meetings online | `meetings`, `meeting_rsvps`, `AddEditMeetingSheet` |
| Sobriety milestone tracking | `sobriety_milestones`, `sobriety_change_log` |
| Crisis support | `ContentSafetyEngine` |
| Serves alumni in Florida and Ohio | `README.md` |
| Coming early October | Pre-launch, awaiting App Store review |

**One thing to confirm before you render:** the scripts say "alumni meetings
online" rather than "alumni Zoom meetings." Naming Zoom is a third-party brand
claim. If the app genuinely uses Zoom, swap the word in; if it is generic video
sessions, leave it as written.

---

## 3. The scripts

Two clips each. Clip 2 continues mid-thought — no second greeting, no
reintroduction. CAPS mark the one volume spike per line; the model under-renders
flat prose, so the emphasis is load-bearing, not decoration.

### Ohio — 57 words

**Clip 1 (0–15s) — HOOK + SETUP — 28 words**

> Early October, Milton Recovery puts something in your pocket. It's called
> Milton Nation Alumni — and it's built for ONE thing: keeping this community
> together after you walk out.

**Clip 2 (15–30s) — APPLY + CLOSER — 29 words**

> Your care team, one tap away. Peers who got sober beside you. AA and NA
> meetings near you, alumni meetings online. Ohio — this one's OURS. Let's go,
> Milton Nation.

### Florida — 56 words

**Clip 1 (0–15s) — HOOK + SETUP — 28 words**

> Early October, something new drops from Milton Recovery. It's called Milton
> Nation Alumni — one app built to keep this WHOLE community connected, long
> after you leave the program.

**Clip 2 (15–30s) — APPLY + CLOSER — 28 words**

> Chat with your care team. Find AA and NA meetings near you. Alumni meetings
> online, peer support, sobriety milestones — all in one place. Florida, LET'S
> GO. Milton Nation.

### Persona sentence — carry verbatim into every prompt

Restate this in the character prompt, both board prompts, and both clip prompts.
Stated once, it drifts.

> A warm, grounded Milton Recovery team member — steady and genuinely glad about
> this, one honest human-scale lift at the end, never hyped, never salesy.

---

## 4. Character prompts

One `character_media_id` per video, generated once and locked across every board
and clip. Never regenerate mid-run.

Model `soul_2`, `aspect_ratio: 3:4`, `quality: 2k`, `count: 1`.

### Why both say "overcast" and "open shade"

The realism spec bans golden hour, warm sunset, and any orange or amber cast —
warm light is what makes these renders read as stock footage. Florida in
neutral open shade still reads unmistakably as Florida: it is the palms, stucco
and sea grape that carry the location, not the colour temperature.

### 4.1 Ohio presenter

```
A man in his mid-thirties, mid-thought, slight half-smile, eyes glancing slightly
off-lens, short dark-brown hair with a neat natural texture, lean athletic build,
with high model facial features, symmetrical features, well-proportioned figure,
natural skin texture, standing on a tree-lined residential sidewalk in a
Midwestern town with red-brick storefronts and mature maples behind him.
Soft even overcast daylight falls across his face — neutral, clean, no warm cast,
no retouched glow. Skin texture is real, with visible pores and natural
unevenness.
He wears a heather-grey quarter-zip pullover over a plain navy crew tee, full
coverage, relaxed fit, sleeves at the wrist. Body in a calm neutral pose —
relaxed standing, one hand resting naturally.
The background features weathered red brick, a painted storefront sign well out
of focus, maple leaves just turning, grey pavement, a parked car far back.
Color palette dominated by cool grey, muted brick red, and deep green.
Casual handheld iPhone selfie taken by him at arm's length — head and shoulders
fill the frame, slight natural tilt, slightly off-center, intuitive composition,
captured mid-moment. Subject in clear focus with the background naturally falling
out as in any phone photo.
Shot on iPhone front-facing camera. Phone-sensor grain and realistic skin texture
preserved, no retouch, no smooth-skin filter. No fisheye lens, no ultra-wide
distortion. Authentic UGC creator phone selfie, NOT editorial portrait, NOT
fashion magazine.
```

### 4.2 Florida presenter

```
A woman in her early thirties, mid-action expression — in the middle of saying
something, not posing, dark wavy shoulder-length hair loosely tied back, slim
athletic build, with high model facial features, symmetrical features,
well-proportioned figure, natural skin texture, standing on a palm-lined sidewalk
outside a low white stucco building in coastal Florida.
Bright open-shade daylight falls across her face — neutral, clean, no warm cast,
no golden-hour glow, no orange tone. Skin texture is real, with visible pores and
natural unevenness.
She wears a soft sage-green short-sleeve button-down shirt, fully buttoned,
relaxed fit, full coverage, over plain stone-coloured trousers. Body in a calm
neutral pose — relaxed standing, one hand resting naturally.
The background features a white stucco wall, sabal palms, a clipped sea-grape
hedge, pale concrete walkway, bright flat sky.
Color palette dominated by cool white, muted sage, and soft green — no amber, no
orange.
Casual handheld iPhone selfie taken by her at arm's length — head and shoulders
fill the frame, slight natural tilt, slightly off-center, intuitive composition,
captured mid-moment. Subject in clear focus with the background naturally falling
out as in any phone photo.
Shot on iPhone front-facing camera. Phone-sensor grain and realistic skin texture
preserved, no retouch, no smooth-skin filter. No fisheye lens, no ultra-wide
distortion. Authentic UGC creator phone selfie, NOT editorial portrait, NOT
fashion magazine.
```

---

## 5. Board prompts

Each board is a 21:9 sheet of eight vertical 9:16 slots. Those eight slots become
eight internal hard cuts inside one clip — that cut rhythm is what makes it read
as a real creator's video rather than one long static take.

Model `gpt_image_2`, `aspect_ratio: 21:9`, `resolution: 2k`, `quality: high`,
`medias: [character_media_id]`. Board 2 additionally takes the cleaned board 1
job ID as its final image media.

### Board 1 — HOOK + SETUP (both states)

Swap the bracketed location block for the state you are rendering.

```
A horizontal 21:9 storyboard sheet divided into eight equal side-by-side vertical
9:16 slots, each a still frame from one continuous selfie walk-and-talk filmed by
the same person on an iPhone front-facing camera at arm's length.

The subject is the person in the reference image — same face, same hair, same
outfit in every slot. A warm, grounded Milton Recovery team member — steady and
genuinely glad about this, never hyped, never salesy.

[OHIO: walking along a tree-lined Midwestern sidewalk, red-brick storefronts and
turning maples drifting past behind them, soft even overcast daylight, cool grey
and muted brick palette.]
[FLORIDA: walking along a palm-lined sidewalk past a low white stucco building,
sabal palms and sea-grape hedge drifting past behind them, bright open-shade
daylight, cool white and sage palette.]

Slot 1: mid-stride, already talking, mouth open mid-word, eyes toward the lens.
Slot 2: half-step closer to the lens, slight tilt, mid-sentence.
Slot 3: glancing briefly off-lens then back, background shifted noticeably.
Slot 4: head-and-shoulders, eyebrows lifted mid-thought.
Slot 5: slight turn of the shoulders as they keep walking, framing off-center.
Slot 6: closer crop, mid-word, one honest half-smile beginning.
Slot 7: framing drops slightly as the arm relaxes, background further along.
Slot 8: steady mid-sentence, calm and direct.

Continuous forward walking motion across all eight slots — the background must
visibly progress from slot to slot, never repeat. Handheld micro-shake, framing
slightly different in every slot, never centered, never symmetric.

Phone-sensor grain and realistic skin texture preserved in every slot, no
retouch, no smooth-skin filter, no beauty filter. No fisheye, no ultra-wide
distortion, no shallow depth of field, no bokeh, no cinematic grade, no
teal-orange. Deep focus, flat authentic iPhone footage.

No text of any kind, no captions, no subtitles, no watermark, no slot labels, no
logos, no product, no phone visible in frame other than the implied one being
held.
```

### Board 2 — APPLY + CLOSER

Identical to board 1 with these two changes:

- Slot 1 opens **mid-sentence already in progress** — no greeting beat, no
  reintroduction, the walk simply continues.
- Slots 6–8 carry the close: slot 6 a genuine grin breaking, slot 7 a small
  affirming nod, slot 8 settling to a calm direct look at the lens.

Keep the location, the outfit, the light and the palette identical to board 1.

---

## 6. Clip prompts

Model `seedance_2_5`, `aspect_ratio: 9:16`, `resolution: 1080p`, `duration: 15`,
`mode: omni_reference`, `generate_audio: true`,
`medias: [clean_board_job_id, character_media_id]`.

Submit both clips through `generate_video_batch` with stable indices. Do **not**
call `generate_audio` separately.

```
Eight hard cuts, one per slot of the reference storyboard sheet, in order, no
transitions, no dissolves, no camera moves other than natural handheld walking.

The person from the reference speaks continuously to camera in a natural American
accent, walking the whole time, filming themselves on an iPhone front-facing
camera at arm's length.

Persona: a warm, grounded Milton Recovery team member — steady and genuinely glad
about this, one honest human-scale lift at the end, never hyped, never salesy.

They say, exactly and only:
"<PASTE THE CLIP SEGMENT FROM SECTION 3 HERE>"

Delivery: conversational pace, real breath between sentences, natural mouth
movement matched to every word. Emphasis on the capitalised word only. No staged
pauses, no announcer voice, no shouting.

Ambient outdoor sound only — light wind, distant traffic, footsteps. No music.

Phone-sensor grain and realistic skin texture preserved, no retouch, no
smooth-skin filter. Deep focus, flat authentic iPhone footage, no cinematic
grade. No text, no captions, no subtitles, no watermark, no logos.
```

Paste the matching segment from section 3 into the quoted slot — Ohio clip 1,
Ohio clip 2, Florida clip 1, Florida clip 2. Everything else stays byte-identical
between clips so the identity holds.

---

## 7. The de-slop pass — do not skip it

Between the board and the clip, every raw board goes through `seedream_v5_pro`
at 21:9 / 2k with the board's own result imported as `image_references`. This is
the step that converts a competent AI image into something that reads as a real
phone photo — pore-level skin, true sensor noise, no waxy plastic sheen.

Skipping it is the difference between "that's AI" and "who filmed this?" It is
also cheap relative to the video render. Run it on both boards, both states.

---

## 8. If credits are short

In priority order:

1. **Top up and render both at 30s.** ~421 credits. This is the deliverable as
   specified.
2. **Render Ohio first at 30s, Florida later.** ~211 credits. The character,
   board and clip prompts for Florida stay on file and cost nothing to hold.
3. **Cut both to 15s.** One board, one clip, `FULL_ARC` role, 28–35 words each —
   which means clip 1 of each script plus the closing line. About 107 credits for
   the pair. Noticeably less room to land the feature list, but it is a real
   video rather than a compromise on realism.

Do not drop to 480p to save credits. The whole point of this pack is that the
person looks real, and 480p undoes it.

---

## 9. Portable version — any other tool

If you paste into a different engine, that engine will not have the board/clip
structure. Use this single block per video, and expect to run it twice (once per
15s half) or accept a shorter result.

```
Hyper-realistic vertical 9:16 selfie video, 15 seconds. A [man in his
mid-thirties / woman in her early thirties] with high model facial features,
symmetrical features, natural skin texture with visible pores, filming themselves
on an iPhone front-facing camera at arm's length while walking along a
[tree-lined Midwestern sidewalk with red-brick storefronts and turning maples /
palm-lined Florida sidewalk past a low white stucco building with sabal palms].
Soft even [overcast / open-shade] daylight, neutral and cool, no warm cast, no
golden hour, no orange tone.

They speak to camera continuously in a natural American accent, warm and
grounded, never hyped. They say, exactly and only:
"<PASTE SEGMENT>"

Handheld micro-shake, slightly off-center framing, continuous forward walking
with the background visibly progressing. Phone-sensor grain, no retouch, no
smooth-skin filter, no beauty filter, deep focus, flat authentic iPhone footage.
No fisheye, no ultra-wide, no bokeh, no cinematic colour grade, no teal-orange.
No text, no captions, no subtitles, no watermark, no logos, no music. Ambient
outdoor sound only.
```

---

## 10. Pre-flight checklist

- [ ] Balance covers the render you are about to start (section 0)
- [ ] "Zoom" wording confirmed or left as "alumni meetings online" (section 2)
- [ ] Launch timing still "early October"
- [ ] Character image generated once per state and locked
- [ ] De-slop pass run on both boards
- [ ] Script pasted exactly — no words added back in
- [ ] Presenter never claims to be an alumnus
- [ ] No music requested; ambient only
- [ ] Captions decided after render, burned from a real transcript, never planned

---

## 11. Render log — 2026-09-02

One video rendered on the balance available (61.08 credits), no top-up.
Final balance 3.72. Every charge matched its preflight quote exactly.

### Decisions made on the day

- **One video names both states.** With budget for a single render, a cut that
  says "Florida, Ohio" serves the whole alumni base. Location is a neutral
  American sidewalk — brick-and-glass building, green trees — no palms, no
  turning maples, so it belongs to neither state and excludes neither.
- **Seedance 2.0 std at 12s over Seedance 2.5 at 8s.** Real per-second prices
  (9:16, native audio): 2.5 = 6.5 cr/s at 720p, 9 cr/s at 1080p; 2.0 std = 4.5
  cr/s at 720p. Same identity/native-audio lineage; 12 seconds holds an actual
  announcement (20–28 words), 8 seconds holds a teaser. The budget models
  (2.0 mini, Kling, Wan at 2.5 cr/s) were priced and rejected — the face is
  the one place not to save.
- **One continuous take, no storyboard.** The 8-cut board is a 15-second
  TikTok-ad convention; eight cuts in twelve seconds reads frantic. A single
  unbroken handheld selfie take is how a real person films this, and it is the
  most robust shape for lip-sync on a one-shot render. Skipping the
  `gpt_image_2` board also freed its credits for video seconds.
- **720p, not 1080p.** Instagram and TikTok deliver vertical video at ~720p
  regardless. Realism comes from the presenter still and the iPhone-grain
  prompting, not the resolution tier.

### Spend

| Step | Model | Config | Credits |
|---|---|---|---|
| 3 presenter candidates | `soul_2` | 9:16, 2k | 0.36 |
| Logo removal + realism pass on the pick | `seedream_v5_pro` | 9:16, 2k, inpaint | 3.00 |
| Video | `seedance_2_0` | std, 720p, 12s, 9:16, audio | 54.00 |
| | | **Total** | **57.36** |

### Casting

Three stills generated, one prompt each: two women (dark hair / navy polo;
light hair / grey sweatshirt) and one man (beard / navy quarter-zip).

- Grey-sweatshirt candidate rejected: glossy, contoured, beauty-filter skin —
  the exact AI-tell the pack is built to avoid.
- Navy-polo candidate: genuinely real, rule-perfect neutral light, held as
  fallback. Expression read flat for a "let's go" line.
- **Bearded man selected.** Best skin texture, warmest face, mouth already
  mid-word. One defect: a gibberish orange brand mark on the chest. Removed
  with the realism pass in a single Seedream edit (`is_inpaint: true`,
  reference = the raw still), verified clean before the video spend.

### Script as rendered — 27 words

> Early October, Milton Recovery launches Milton Nation Alumni. Your care
> team, A.A. and N.A. meetings near you, your people — ONE app. Florida,
> Ohio — let's go, Milton Nation.

"A.A." and "N.A." are written with periods so the model reads them as
letters, and so they are not mistaken for CAPS volume spikes — "ONE" is the
single spike in the line.

### Video prompt as submitted

Medias: the cleaned still as both `start_image` and `image_references`.

```
Style & Mood: UGC iPhone aesthetic, soft even overcast daylight, neutral and
clean, front-facing camera, intimate handheld feel, one continuous take with
no cuts, social media vertical format.

Narrative Summary: A warm, grounded Milton Recovery team member walks along
the sidewalk and announces the Milton Nation Alumni app straight to camera in
one unbroken selfie take, then lands the closer with one honest grin —
performed by a natural, engaged creator — genuine reactions, lively but
human, never staged screaming energy.

Dynamic Description:
One continuous handheld selfie take, 0-12s, MEDIUM CLOSE-UP SELFIE: frame one
is already mid-stride and mid-word — his head settling from a glance back to
the lens as the first word lands, his near arm extended toward the lens just
out of frame, the other arm swinging naturally at his side. He keeps walking
forward the entire time; the brick-and-glass building and the strip of lawn
slide past behind him, the sidewalk perspective shifts, a parked car passes
far back. At "Milton Nation Alumni" a small affirming nod, then a
closed-mouth beat — lips together, a short breath through the nose — before
"Your care team". Through the feature list his eyebrows lift once on "your
people", a half-smile pulling at one side of his mouth; a slight tilt of the
head as the framing drifts off-center and corrects. On "ONE app" a single
emphatic dip of the chin. On "Florida, Ohio" his eyes brighten, a real grin
breaks on "let's go", and he holds the lens with a calm steady look on
"Milton Nation" as the take ends, still walking.

Static Description: A quiet tree-lined sidewalk outside a low modern
brick-and-glass building, a strip of green lawn with a low brick edge, grey
concrete path, leafy green trees, a car far back; soft overcast daylight from
above, deep focus with the background sharp.

Audio: He speaks to camera in a natural American accent, warm and unhurried,
iPhone microphone audio with light outdoor ambience — faint wind, distant
traffic, his footsteps: "Early October, Milton Recovery launches Milton
Nation Alumni. Your care team, A.A. and N.A. meetings near you, your people —
ONE app. Florida, Ohio — let's go, Milton Nation."

Facial features clear and undistorted, consistent clothing throughout — plain
navy quarter-zip over a white tee. Shot on iPhone, natural lighting, social
media aesthetic, slight natural handheld micro-shake from his grip, one
continuous take, no cuts, no transitions. No on-screen text, no subtitles, no
captions, no watermarks, no legible text on any object, no real brand logos
anywhere, no phone visible in frame, no mirror, no reflection, no cinematic
grade, no film grain, no bokeh, no lens flare, no fisheye lens, no ultra-wide
distortion, no slow motion, no beauty filter, no music, no third arm, no
extra hands, no duplicated limbs, no deformed hands.
```

### QA — verified before delivery

- **Streams:** 12.05s, 720×1280, 24 fps, AAC stereo. Speech peaks at −2.5 dB,
  mean −19.8 dB, no clipping.
- **Words:** transcribed with faster-whisper from the rendered audio —
  verbatim, 27 of 27 words in order. First word lands at 0.00s (hook law
  held); last word ends at 11.62s, so the closer sits inside the take with
  nothing clipped. "A.A. and N.A." rendered as letters; "one" stretches to
  0.76s — the written emphasis spike, delivered.
- **Frames** at 0.2 / 1.5 / 3 / 4.5 / 6 / 7.5 / 9 / 10.5 / 11.8s: identity
  constant across all nine, walking motion real (building and brick edge
  progress frame to frame), no phone, no text, no logo, no extra limbs. The
  grin lands at 10.5s on "let's go"; a calm steady look closes on "Milton
  Nation".
- **Output:** `milton-nation-spokesperson-12s.mp4`, 11.6 MB, delivered as a
  file. Hosted result retained in the Higgsfield account.
- **Balance after:** 3.72 credits.
