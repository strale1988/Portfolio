#!/usr/bin/env python3
"""
Regenerates gallery.json from whatever image and video files are sitting in
this folder.

Run this any time you add or remove images/videos:
    python3 gallery/generate_manifest.py

Files are listed newest-first, sorted by filename in reverse alphabetical order,
so START EVERY FILENAME WITH ITS YEAR, e.g. "2026_Lobby_Cam01.webp". The site
reads the year from that prefix to group the Archive by year.

Anything you've added to an entry by hand is kept when you re-run this:
    caption   text shown under the image in the lightbox
    poster    (videos) thumbnail image to show before playback
    featured  a number (1, 2, 3...) pins it to that position at the top of its
              view (Visualization / Animation). Everything without a number
              follows, newest first. `true` pins it after the numbered ones.
    category  "visualization" or "animation" to override the default
              (images -> visualization, videos -> animation)
New files get an empty caption, and are not featured until you say so.
"""
import json
import os
import re

IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif'}
VIDEO_EXTENSIONS = {'.mp4', '.webm', '.mov', '.m4v'}
EXTENSIONS = IMAGE_EXTENSIONS | VIDEO_EXTENSIONS
HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, 'gallery.json')


def main():
    existing = {}
    if os.path.exists(MANIFEST):
        with open(MANIFEST, encoding='utf-8') as f:
            try:
                for entry in json.load(f):
                    if isinstance(entry, dict) and entry.get('file'):
                        existing[entry['file']] = entry
            except json.JSONDecodeError:
                pass  # start fresh if the file is empty/malformed

    files = sorted(
        (f for f in os.listdir(HERE) if os.path.splitext(f)[1].lower() in EXTENSIONS),
        key=str.lower,
        reverse=True
    )

    manifest = []
    for f in files:
        prev = existing.get(f, {})
        ext = os.path.splitext(f)[1].lower()
        entry = {'file': f, 'caption': prev.get('caption', '')}
        if ext in VIDEO_EXTENSIONS:
            entry['type'] = 'video'
        # Carry over everything else already on the entry (poster, featured,
        # category, ...) so hand edits survive a re-run.
        for key, value in prev.items():
            if key == 'type' and ext not in VIDEO_EXTENSIONS:
                continue  # a stale "video" flag on something that's now an image
            entry.setdefault(key, value)
        manifest.append(entry)

    with open(MANIFEST, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write('\n')

    n_video = sum(1 for e in manifest if e.get('type') == 'video')
    n_image = len(manifest) - n_video
    n_featured = sum(1 for e in manifest if e.get('featured'))
    print(f"gallery.json updated - {n_image} image(s), {n_video} video(s) listed, {n_featured} featured.")

    removed = sorted(set(existing) - set(files))
    if removed:
        print(f"Dropped {len(removed)} entr{'y' if len(removed) == 1 else 'ies'} whose file no longer exists:")
        for name in removed:
            print(f"  - {name}")

    undated = [e['file'] for e in manifest if not re.match(r'\d{4}', e['file'])]
    if undated:
        print(f"\nNo year prefix on {len(undated)} file(s) - they'll appear under 'Undated' in the Archive:")
        for name in undated:
            print(f"  - {name}")


if __name__ == '__main__':
    main()
