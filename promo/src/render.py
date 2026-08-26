import sys, os, time
from film import render, FPS, DUR
fmt = sys.argv[1]; out = f'frames_{fmt}'
os.makedirs(out, exist_ok=True)
n = int(DUR*FPS); t0=time.time()
for i in range(n):
    render(i/FPS, fmt).save(f'{out}/{i:05d}.jpg', quality=94, subsampling=0)
    if i % 60 == 0:
        el=time.time()-t0
        print(f'{i}/{n}  {el:.0f}s  eta {el/(i+1)*(n-i):.0f}s', flush=True)
print('DONE', time.time()-t0, flush=True)
