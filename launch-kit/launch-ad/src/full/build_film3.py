#!/usr/bin/env python3
"""Assemble film3.html from _film3.js plus film2's inlined-font <style> block."""
head = open('film2.html').read()
style = head[head.index('<style>'):head.index('</style>')+8]
body = open('_film3.js').read()
open('film3.html','w').write(
    '<!doctype html><html><head><meta charset="utf-8">' + style +
    '</head><body>\n<canvas id="c" width="1080" height="1920"></canvas>\n'
    '<script src="style.js"></script>\n<script src="device.js"></script>\n'
    '<script src="plates.js"></script>\n<script src="grade.js"></script>\n'
    '<script>\n' + body + '\n</script></body></html>\n')
print('film3.html rebuilt')
