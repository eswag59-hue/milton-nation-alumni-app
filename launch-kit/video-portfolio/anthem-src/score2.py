"""Anthem score v2 — minimal, modern, spacious. Felt-piano plucks, warm sub
thumps on every cut, quiet air, one lift at the end. Timeline-driven so the
cutdowns get mixes synced to their own segment boundaries. Pure python."""
import math, wave, struct, random

SR = 44100
OUT = '/tmp/claude-0/-home-user-milton-nation-alumni-app/dd2da122-5343-58be-9237-b6e112802222/scratchpad/video/out'

# pentatonic-ish D major palette
N = dict(D3=146.83, E3=164.81, Fs3=185.0, A3=220.0, B3=246.94,
         D4=293.66, E4=329.63, Fs4=369.99, A4=440.0, B4=493.88,
         D5=587.33, Fs5=739.99, A5=880.0, D2=73.42, A2=110.0)

class Mix:
    def __init__(self, dur):
        self.n = int(SR * (dur + 3.0))
        self.L = [0.0] * self.n; self.R = [0.0] * self.n; self.dur = dur
    def pluck(self, f, t0, amp=0.16, pan=0.0, soft=False):
        """felt piano: fast attack, exp decay, few partials, slightly humanized"""
        t0 += random.uniform(-0.012, 0.012); amp *= random.uniform(0.9, 1.05)
        i0 = max(0, int(t0 * SR)); dur = 1.6
        i1 = min(self.n, i0 + int(dur * SR))
        parts = [(1, 1.0), (2, 0.32 if not soft else 0.18), (2.98, 0.12), (4.1, 0.05)]
        lg = amp * (0.5 - 0.5 * pan); rg = amp * (0.5 + 0.5 * pan)
        for i in range(i0, i1):
            t = (i - i0) / SR
            a = min(1.0, t / 0.008) * math.exp(-t * 3.4)
            s = 0.0
            for m, g in parts: s += g * math.sin(2 * math.pi * f * m * t)
            s *= a
            self.L[i] += s * lg; self.R[i] += s * rg
    def sub(self, t0, amp=0.34, f=51.0):
        i0 = max(0, int(t0 * SR)); i1 = min(self.n, i0 + int(1.5 * SR))
        for i in range(i0, i1):
            t = (i - i0) / SR
            fr = f + 26 * math.exp(-t * 16)
            s = math.sin(2 * math.pi * fr * t) * math.exp(-t * 3.2) * amp * min(1, t / 0.004)
            self.L[i] += s; self.R[i] += s
    def air(self, t0, t1, fs, amp=0.028):
        """barely-there high shimmer, slow tremolo"""
        i0, i1 = max(0, int(t0 * SR)), min(self.n, int((t1 + 1.5) * SR))
        ws = [2 * math.pi * (f + d) / SR for f in fs for d in (-0.4, 0.5)]
        for i in range(i0, i1):
            t = i / SR
            e = min(1, (t - t0) / 2.2) * min(1, max(0, (t1 + 1.5 - t) / 1.5))
            trem = 0.75 + 0.25 * math.sin(2 * math.pi * 0.31 * t)
            s = sum(math.sin(w * i) for w in ws) / len(ws) * amp * e * trem
            self.L[i] += s * 0.9; self.R[i] += s * 1.1
    def swell(self, t0, t1, fs, amp=0.10):
        """slow-attack warm chord peaking at t1, releasing after"""
        i0, i1 = max(0, int(t0 * SR)), min(self.n, int((t1 + 2.6) * SR))
        ws = [(2 * math.pi * f / SR, 2 * math.pi * (f + 0.7) / SR) for f in fs]
        for i in range(i0, i1):
            t = i / SR
            if t < t1: e = ((t - t0) / (t1 - t0)) ** 2
            else: e = max(0.0, 1 - (t - t1) / 2.6)
            s = sum(math.sin(w1 * i) + 0.5 * math.sin(w2 * i) for w1, w2 in ws) / (2 * len(ws)) * amp * e
            self.L[i] += s; self.R[i] += s
    def write(self, path):
        out = wave.open(path, 'w'); out.setnchannels(2); out.setsampwidth(2); out.setframerate(SR)
        total = int(self.dur * SR); frames = bytearray()
        for i in range(total):
            t = i / SR; g = 1.0
            if t < 0.9: g = t / 0.9
            if t > self.dur - 1.4: g = max(0.0, (self.dur - t) / 1.4)
            for ch in (self.L, self.R):
                s = math.tanh(ch[i] * 0.9) * g
                frames += struct.pack('<h', int(max(-1, min(1, s)) * 32767))
        out.writeframes(bytes(frames)); out.close()
        print(path.split('/')[-1], f"{self.dur}s")

MOTIF = ['D4', 'A4', 'B4', 'Fs4']          # the Milton four notes

def treat(m, name, t, d):
    """one segment's music. t = start, d = duration."""
    r = random.Random(name)
    m.sub(t + 0.10)                          # every cut lands on a warm thump
    if name == 'opener':
        m.pluck(N['D4'], t + 1.0, 0.14, -0.2); m.pluck(N['A4'], t + 2.6, 0.12, 0.25)
        m.air(t + 1.5, t + d, [N['A5']])
    elif name == 'icon':
        for i, nn in enumerate(MOTIF): m.pluck(N[nn], t + 0.5 + i * 0.62, 0.16, -0.3 + i * 0.2)
    elif name == 'home':
        m.pluck(N['D4'], t + 0.6, 0.15, -0.2); m.pluck(N['Fs4'], t + 1.45, 0.13, 0.1)
        m.pluck(N['A4'], t + 2.3, 0.14, 0.3); m.pluck(N['D5'], t + 3.6, 0.11, 0.0, soft=True)
        m.pluck(N['B3'], t + 4.7, 0.13, -0.25); m.pluck(N['A4'], t + 5.8, 0.11, 0.2, soft=True)
        m.air(t + 1.0, t + d, [N['Fs5']])
    elif name == 'counter':
        for i, (dt, nn) in enumerate([(0.45,'D4'),(1.15,'E4'),(1.85,'Fs4'),(2.55,'A4'),(3.3,'D5')]):
            m.pluck(N[nn], t + dt, 0.17, -0.2 + i * 0.12)
            if i == 4: m.sub(t + dt, 0.30)
    elif name == 'community':
        seq = [(0.5,'D4'),(1.1,'Fs4'),(1.75,'A4'),(2.5,'B4'),(3.3,'A4'),(4.1,'Fs4'),(4.9,'D5'),(5.7,'A4')]
        for i, (dt, nn) in enumerate(seq):
            if dt < d - 0.6: m.pluck(N[nn], t + dt, 0.12 + 0.02 * (i % 2), math.sin(i) * 0.35, soft=(i % 2 == 1))
        m.air(t + 0.8, t + d, [N['A5'], N['Fs5']])
    elif name == 'chat':
        m.pluck(N['B3'], t + 0.7, 0.13, -0.3); m.pluck(N['D4'], t + 1.9, 0.12, 0.1, soft=True)
        m.pluck(N['A4'], t + 3.8, 0.13, 0.3)   # lands with the sent message
        m.pluck(N['Fs4'], t + 4.6, 0.10, 0.0, soft=True)
    elif name == 'meetings':
        for i, (dt, nn) in enumerate([(0.6,'D4'),(1.5,'A4'),(2.4,'B4'),(3.4,'Fs4'),(4.4,'A4')]):
            if dt < d - 0.6: m.pluck(N[nn], t + dt, 0.12, -0.25 + i * 0.13)
    elif name == 'dark':
        m.pluck(N['D3'], t + 0.8, 0.15, -0.15); m.pluck(N['A3'], t + 2.1, 0.13, 0.15)
        m.pluck(N['Fs3'], t + 3.4, 0.12, 0.0, soft=True)
        m.air(t + 1.2, t + d, [N['D5']])
    elif name == 'badges':
        for i, (dt, nn) in enumerate([(0.6,'D4'),(1.25,'Fs4'),(1.75,'A4'),(2.5,'D5'),(3.7,'B4')]):
            if dt < d - 0.6: m.pluck(N[nn], t + dt, 0.13, -0.2 + i * 0.12)
    elif name == 'end':
        m.swell(t - 1.3, t + 0.15, [N['D3'], N['A3'], N['D4']], 0.09)   # rise into the cut
        m.sub(t + 0.12, 0.4)
        m.swell(t + 0.2, t + 2.6, [N['D3'], N['Fs3'], N['A3'], N['D4'], N['Fs4']], 0.11)
        for i, nn in enumerate(MOTIF + ['D5']):
            m.pluck(N[nn], t + 0.8 + i * 0.55, 0.15, -0.25 + i * 0.13)
        m.air(t + 1.0, t + d - 1.0, [N['A5'], N['Fs5']], 0.035)
        m.pluck(N['D5'], t + d - 2.6, 0.12, 0.0, soft=True)

def build(path, timeline):
    dur = sum(d for _, d in timeline)
    m = Mix(dur); t = 0.0
    for name, d in timeline:
        treat(m, name, t, d); t += d
    m.write(f"{OUT}/{path}")

random.seed(11)
MASTER = [('opener',5.0),('icon',4.0),('home',8.0),('counter',4.5),('community',7.0),
          ('chat',6.5),('meetings',6.0),('dark',5.5),('badges',6.0),('end',9.0)]
build('score-master.wav', MASTER)                                    # 61.5s
build('score-cut30.wav', [('icon',4.0),('home',8.0),('counter',4.5),('community',7.0),('end',7.0)])
build('score-cut15.wav', [('icon',3.5),('counter',4.5),('end',7.0)])
