#!/usr/bin/env python3
"""The 52s score for the commercial: solo piano -> strings -> full swell ->
back to solo piano. The last note is the first note; that circle is the point.

Pure numpy — no scipy on this box — written as raw float32 for ffmpeg to
encode. Cut points match the beat boundaries in src/film/film.html exactly, so
the music lands with the picture rather than under it.
"""
import numpy as np, subprocess, sys, pathlib

SR   = 44100
DUR  = 52.0
N    = int(SR*DUR)
t    = np.arange(N)/SR

# D minor: warm, serious, resolves hopeful.  i - VI - III - VII
def hz(semi): return 440.0*2**((semi-9)/12)     # semi 0 = C4
D3,F3,A3,Bb3,C4,D4,F4,A4,Bb4,C5,D5,F5,A5 = [hz(s) for s in
    (-10,-7,-3,-2,0,2,5,9,10,12,14,17,21)]

# ── piano ────────────────────────────────────────────────────────────────
def piano(f, start, dur, amp=1.0):
    """Struck string: harmonics with per-partial decay, slight inharmonicity,
    plus a hammer transient. Cheap, but it reads as a real piano because the
    top partials die first."""
    i0 = int(start*SR); n = int(dur*SR)
    if i0 >= N: return
    n = min(n, N-i0)
    lt = np.arange(n)/SR
    sig = np.zeros(n)
    B = 0.0004                                   # inharmonicity
    for k in range(1, 15):
        fk = f*k*np.sqrt(1+B*k*k)
        if fk > SR/2.2: break
        decay = np.exp(-lt*(1.2 + k*0.75))       # highs die first
        sig += (1.0/k**1.35)*decay*np.sin(2*np.pi*fk*lt + k*0.7)
    # hammer noise, very short
    hn = int(0.006*SR)
    if hn < n:
        rng = np.random.default_rng(int(f*10))
        sig[:hn] += rng.standard_normal(hn)*np.exp(-np.arange(hn)/(hn/3))*0.28
    sig *= np.minimum(lt/0.004, 1.0)             # click-free attack
    out[i0:i0+n] += sig*amp*0.20

# ── strings ──────────────────────────────────────────────────────────────
def strings(f, start, dur, amp=1.0, detune=0.0035):
    """Six detuned saws, slow bow attack, one-pole lowpass, slow vibrato."""
    i0 = int(start*SR); n = int(dur*SR)
    if i0 >= N: return
    n = min(n, N-i0)
    lt = np.arange(n)/SR
    vib = 1 + 0.0022*np.sin(2*np.pi*4.6*lt + f)
    sig = np.zeros(n)
    for d in (-2.5,-1.5,-0.5,0.5,1.5,2.5):
        fd = f*(1+detune*d)*vib
        ph = np.cumsum(fd)/SR
        sig += 2*(ph - np.floor(ph+0.5))          # saw
    sig /= 6
    # one-pole lowpass, opens as the note swells
    cut = 0.06 + 0.10*np.minimum(lt/2.5, 1.0)
    y = np.zeros(n); prev = 0.0
    for i in range(n):                            # vectorising this changes the
        prev += cut[i]*(sig[i]-prev)              # filter's character; n is small
        y[i] = prev
    att  = np.minimum(lt/1.4, 1.0)**1.6
    rel  = np.minimum((dur-lt)/1.2, 1.0).clip(0,1)
    out[i0:i0+n] += y*att*rel*amp*0.16

def sub(f, start, dur, amp=1.0):
    i0=int(start*SR); n=min(int(dur*SR), N-i0)
    if i0>=N or n<=0: return
    lt=np.arange(n)/SR
    env=np.minimum(lt/0.9,1.0)*np.minimum((dur-lt)/0.9,1.0).clip(0,1)
    out[i0:i0+n] += np.sin(2*np.pi*f*lt)*env*amp*0.30

def swell(start, dur, amp=1.0):
    """Filtered noise rising into a hit — the lift-off at 22.5s."""
    i0=int(start*SR); n=min(int(dur*SR), N-i0)
    if i0>=N or n<=0: return
    rng=np.random.default_rng(7)
    lt=np.arange(n)/SR
    nz=rng.standard_normal(n)
    y=np.zeros(n); prev=0.0
    for i in range(n):
        prev += 0.010*(nz[i]-prev); y[i]=prev
    out[i0:i0+n] += y*(lt/dur)**2.4*amp*3.2

out = np.zeros(N)

# ── the arrangement, cut to the film's beats ─────────────────────────────
# 0.0-5.0 LOGO — one piano note, alone
piano(D4, 0.4, 5.0, 1.0); piano(A4, 2.3, 3.6, 0.45)
sub(D3*0.5, 0.4, 6.0, 0.5)

# 5.0-11.0 PHONE — the phrase opens
for k,(f,st) in enumerate([(F4,5.2),(A4,6.4),(D5,7.6),(C5,9.2)]):
    piano(f, st, 3.2, 0.85-k*0.06)
sub(D3*0.5, 5.0, 6.2, 0.6)

# 11.0-18.0 OPEN — strings arrive under it
for f in (D4,F4,A4): strings(f, 11.0, 7.6, 0.55)
piano(D5, 11.4, 3.0, 0.7); piano(A4, 13.6, 2.6, 0.55); piano(F4, 15.8, 3.0, 0.6)
sub(D3*0.5, 11.0, 7.4, 0.7)

# 18.0-22.5 HOME — Bb, the lift in the progression
for f in (Bb3,D4,F4): strings(f, 18.0, 5.0, 0.68)
piano(Bb4, 18.2, 2.8, 0.75); piano(D5, 20.2, 2.6, 0.65)
sub(Bb3*0.5, 18.0, 4.8, 0.75)

# 22.5-32.0 LIFT — the swell, everything in
swell(20.9, 1.7, 0.9)
for f in (F3,A3,C4,F4,A4,C5): strings(f, 22.5, 9.8, 0.80)
for f in (C4,F4,A4):          strings(f, 26.6, 5.8, 0.62)   # second bed under the hole at 27s
for k,(f,st) in enumerate([(F5,22.6),(A5,23.6),(C5,24.6),(D5,25.6),(A4,26.6),
                           (C5,27.4),(F5,28.4),(A4,29.4),(D5,30.4),(F5,31.2)]):
    piano(f, st, 2.6, 0.95-k*0.02)
sub(F3*0.5, 22.5, 4.8, 0.9); sub(C4*0.5, 27.3, 4.9, 0.9)
# a slow pulse under the flight
for b in np.arange(22.5, 32.0, 0.75):
    piano(D3, b, 0.7, 0.30)

# 32.0-38.5 MEET — held, wide
for f in (C4,F4,A4,C5): strings(f, 32.0, 6.8, 0.78)
piano(C5, 32.2, 3.0, 0.7); piano(A4, 34.4, 2.8, 0.6); piano(F4, 36.4, 2.6, 0.62)
sub(C4*0.5, 32.0, 6.6, 0.85)
for b in np.arange(32.0, 38.5, 0.75):
    piano(D3, b, 0.7, 0.24)

# 38.5-45.0 CHAT — begins to thin and resolve home
for f in (C4,F4,A4): strings(f, 37.4, 2.4, 0.45)   # overlap the MEET/CHAT seam
for f in (D4,F4,A4): strings(f, 38.5, 6.8, 0.62)
piano(D5, 38.7, 3.0, 0.66); piano(F4, 41.0, 2.8, 0.55); piano(A4, 43.0, 2.6, 0.5)
sub(D3*0.5, 38.5, 6.6, 0.7)

# 45.0-52.0 OUT — back to the note it started on
for f in (D4,F4): strings(f, 45.0, 5.0, 0.40)
piano(D4, 45.2, 6.6, 0.95)      # the first note, again
piano(A4, 47.4, 4.2, 0.40)
piano(D5, 49.4, 2.8, 0.30)
sub(D3*0.5, 45.0, 6.4, 0.55)

# ── dynamics ─────────────────────────────────────────────────────────────
# No gain ride. An earlier pass added one because a measurement appeared to
# show the arc inverted in the back half — but that measurement was taken after
# limiting and normalisation, not on the arrangement. Measured raw, the parts
# already sit where they should:
#   LOGO -19.8  PHONE -17.8  OPEN -16.7  HOME -16.1  LIFT -14.5  MEET -14.9
#   CHAT -17.2  OUT -18.8  (dBFS RMS)
# Builds to the lift, holds through the meeting, decays home. Automation on top
# of that only fought the writing, so the fix was to delete it.

# ── reverb and width ─────────────────────────────────────────────────────
# Width comes from two DECORRELATED reverb tails, not a delay on the dry
# signal. An 11ms Haas delay measured fine in stereo but cost the MEET section
# 10.5 dB when summed to mono — comb filtering notching that chord's low
# content. Phone speakers are mono, so most viewers would have heard a hole in
# the loudest moment. Two independent tails sum harmlessly: the dry stays
# centred and only the diffuse field differs between channels.
def hall(seed, decay=0.85, predelay=0.012, length=2.6):
    rng = np.random.default_rng(seed)
    n  = int(length*SR)
    ir = rng.standard_normal(n) * np.exp(-(np.arange(n)/SR)/decay)
    ir[:int(predelay*SR)] *= 0.10
    return ir / (np.abs(ir).sum()/9.0)

def conv(sig, ir):
    L = 1 << int(np.ceil(np.log2(len(sig)+len(ir))))
    return np.fft.irfft(np.fft.rfft(sig, L)*np.fft.rfft(ir, L))[:len(sig)]

wetL = conv(out, hall(11))
wetR = conv(out, hall(29))
Lc = out*0.80 + wetL*0.55
Rc = out*0.80 + wetR*0.55
st = np.stack([Lc, Rc], axis=1)

# ── master ───────────────────────────────────────────────────────────────
st = np.tanh(st*1.25)/np.tanh(1.25)                  # soft knee
st *= 10**(-1.2/20)/max(np.abs(st).max(), 1e-9)      # -1.2 dBFS
fa, fb = int(0.35*SR), int(1.6*SR)
st[:fa]  *= np.linspace(0,1,fa)[:,None]
st[-fb:] *= np.linspace(1,0,fb)[:,None]**1.5

raw = pathlib.Path(sys.argv[1] if len(sys.argv)>1 else 'build/score.f32')
raw.parent.mkdir(parents=True, exist_ok=True)
st.astype(np.float32).tofile(raw)
print(f"wrote {raw}  {DUR}s  peak={np.abs(st).max():.3f}  rms={np.sqrt((st**2).mean()):.4f}")
