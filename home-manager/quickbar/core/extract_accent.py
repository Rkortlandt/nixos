#!/usr/bin/env python3
import sys
import subprocess
import re
import colorsys
import urllib.parse
import urllib.request
import tempfile
import os

def extract_accent(art_input, fallback="#0ea16f"):
    if not art_input:
        return fallback

    url = urllib.parse.unquote(art_input).strip()
    if not url:
        return fallback

    temp_file = None
    target_path = url

    if url.startswith("file://"):
        target_path = url[7:]
    elif url.startswith("http://") or url.startswith("https://"):
        try:
            fd, temp_file = tempfile.mkstemp(suffix=".img")
            os.close(fd)
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=2.5) as resp, open(temp_file, 'wb') as f:
                f.write(resp.read())
            target_path = temp_file
        except Exception:
            if temp_file and os.path.exists(temp_file):
                os.remove(temp_file)
            return fallback

    if not os.path.exists(target_path):
        if temp_file and os.path.exists(temp_file):
            os.remove(temp_file)
        return fallback

    # Run ImageMagick to get color quantization histogram
    cmd = [
        "magick",
        target_path,
        "-scale", "32x32!",
        "+dither",
        "-colors", "16",
        "-format", "%c\n",
        "histogram:info:"
    ]

    try:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=3)
        out = res.stdout
    except Exception:
        out = ""
    finally:
        if temp_file and os.path.exists(temp_file):
            try:
                os.remove(temp_file)
            except Exception:
                pass

    if not out:
        return fallback

    best_color = None
    best_score = -1.0
    fallback_color = None
    max_count = -1

    for line in out.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        m = re.search(r'^\s*(\d+):.*#([0-9A-Fa-f]{6})', line)
        if not m:
            continue
        count = int(m.group(1))
        hex_code = m.group(2)
        r = int(hex_code[0:2], 16) / 255.0
        g = int(hex_code[2:4], 16) / 255.0
        b = int(hex_code[4:6], 16) / 255.0

        h, l, s = colorsys.rgb_to_hls(r, g, b)

        # Track dominant color with non-extreme lightness as secondary fallback
        if count > max_count and 0.15 <= l <= 0.85:
            max_count = count
            fallback_color = '#' + hex_code

        # We look for saturated, vibrant accent colors
        if l < 0.15 or l > 0.90 or s < 0.12:
            score = s * 0.05
        else:
            # Ideal lightness is 0.35 - 0.70
            lightness_dist = abs(l - 0.52)
            lightness_score = max(0.1, 1.0 - lightness_dist * 1.5)
            # Saturated colors with good pixel count score highest
            score = (s ** 1.1) * lightness_score * (1.0 + min(count / 400.0, 0.6))

        if score > best_score:
            best_score = score
            best_color = '#' + hex_code

    if best_color and best_score > 0.08:
        return best_color
    if fallback_color:
        return fallback_color
    return fallback

if __name__ == "__main__":
    art = sys.argv[1] if len(sys.argv) > 1 else ""
    fb = sys.argv[2] if len(sys.argv) > 2 else "#0ea16f"
    print(extract_accent(art, fb))
