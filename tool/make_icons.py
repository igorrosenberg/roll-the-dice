"""Generates web/icons/*.svg (source art). Render with tool/render_icons.js."""
import os

def cube(scale=1.0):
    cx, cy = 256, 260
    a, b, h = 165 * scale, 95 * scale, 190 * scale
    T = (cx, cy - h); UL = (cx - a, cy - h + b); UR = (cx + a, cy - h + b)
    C = (cx, cy - h + 2 * b); BL = (cx - a, cy + b); BR = (cx + a, cy + b)
    B = (cx, cy + 2 * b - 0); K = (cx, cy)  # K: hidden back-bottom corner
    B = (cx, C[1] + h)
    def pts(*p): return " ".join(f"{x:.1f},{y:.1f}" for x, y in p)
    def mat(o, u, v): return f"matrix({u[0]:.2f} {u[1]:.2f} {v[0]:.2f} {v[1]:.2f} {o[0]:.2f} {o[1]:.2f})"
    def pips(face_pts, r=0.1):
        return "".join(f'<circle cx="{x}" cy="{y}" r="{r}"/>' for x, y in face_pts)
    top = mat(T, (a, b), (-a, b))
    left = mat(UL, (a, b), (0, h))
    right = mat(C, (a, -b), (0, h))
    sw = 6 * scale
    return f'''
  <g stroke="#ffffff" stroke-opacity="0.35" stroke-width="{sw*0.6:.1f}" stroke-dasharray="{8*scale:.0f} {8*scale:.0f}" fill="none">
    <line x1="{K[0]}" y1="{K[1]}" x2="{T[0]}" y2="{T[1]}"/>
    <line x1="{K[0]}" y1="{K[1]}" x2="{BL[0]}" y2="{BL[1]}"/>
    <line x1="{K[0]}" y1="{K[1]}" x2="{BR[0]}" y2="{BR[1]}"/>
  </g>
  <g stroke="#E3F2FF" stroke-opacity="0.85" stroke-width="{sw:.1f}" stroke-linejoin="round">
    <polygon points="{pts(T, UR, C, UL)}" fill="url(#top)"/>
    <polygon points="{pts(UL, C, B, BL)}" fill="url(#left)"/>
    <polygon points="{pts(C, UR, BR, B)}" fill="url(#right)"/>
  </g>
  <polygon points="{pts(T, ((T[0]+UR[0])/2, (T[1]+UR[1])/2), ((UL[0]+C[0])/2, (UL[1]+C[1])/2), UL)}" fill="#ffffff" opacity="0.18"/>
  <g fill="#ffffff" fill-opacity="0.95">
    <g transform="{top}">{pips([(0.5, 0.5)], 0.13)}</g>
    <g transform="{left}">{pips([(0.27, 0.27), (0.73, 0.73)])}</g>
    <g transform="{right}">{pips([(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)])}</g>
  </g>'''

DEFS = '''<defs>
  <linearGradient id="top" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#9AD4FF" stop-opacity="0.80"/>
    <stop offset="1" stop-color="#4FA8F5" stop-opacity="0.70"/>
  </linearGradient>
  <linearGradient id="left" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#3D8FF0" stop-opacity="0.72"/>
    <stop offset="1" stop-color="#1E63C9" stop-opacity="0.62"/>
  </linearGradient>
  <linearGradient id="right" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#1F5FC0" stop-opacity="0.75"/>
    <stop offset="1" stop-color="#123F8C" stop-opacity="0.65"/>
  </linearGradient>
  <radialGradient id="bg" cx="0.5" cy="0.4" r="0.75">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="1" stop-color="#CFE6FF"/>
  </radialGradient>
</defs>'''

def svg(body, bg=False):
    back = '<rect width="512" height="512" fill="url(#bg)"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">{DEFS}{back}{body}</svg>\n'

out = os.path.join(os.path.dirname(__file__), "icons")
os.makedirs(out, exist_ok=True)
open(os.path.join(out, "icon.svg"), "w").write(svg(cube(1.0)))
open(os.path.join(out, "icon-maskable.svg"), "w").write(svg(cube(0.78), bg=True))
open(os.path.join(out, "icon-opaque.svg"), "w").write(svg(cube(0.9), bg=True))
