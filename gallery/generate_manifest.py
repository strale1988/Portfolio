#!/usr/bin/env python3
"""
Regenerates gallery.json from whatever image files are sitting in this folder.

Run this any time you add or remove images:
    python3 gallery/generate_manifest.py

Images are listed newest-first, sorted by filename in reverse alphabetical order
(so prefix filenames with a year/date, e.g. "2026-lobby.jpg", to control ordering).
If a filename already has a caption in gallery.json, that caption is kept;
new images get an empty caption you can fill in by hand afterwards if you want.
"""
import json
import os

EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif'}
HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, 'gallery.json')


def main():
    existing_captions = {}
    if os.path.exists(MANIFEST):
        with open(MANIFEST, encoding='utf-8') as f:
            try:
                for entry in json.load(f):
                    if isinstance(entry, dict) and entry.get('file'):
                        existing_captions[entry['file']] = entry.get('caption', '')
            except json.JSONDecodeError:
                pass  # start fresh if the file is empty/malformed

    files = sorted(
        (f for f in os.listdir(HERE) if os.path.splitext(f)[1].lower() in EXTENSIONS),
        key=str.lower,
        reverse=True
    )

    manifest = [{'file': f, 'caption': existing_captions.get(f, '')} for f in files]

    with open(MANIFEST, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        f.write('\n')

    print(f"gallery.json updated — {len(manifest)} image(s) listed.")


if __name__ == '__main__':
    main()
