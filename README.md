# Portfolio site — how it works

No build step, no framework. Plain HTML/CSS/JS reading plain-text project files.

## Structure

The site now has four separate sections so it's obvious what's what:

- **Where I've worked** — your employment history (companies, roles, dates). Static, from `data/profile.json`.
- **Projects** — apps, tools and interactive projects, browsable by category, listed as text cards with links (no thumbnails). This is the folder-per-project system.
- **Skills** — software, expertise, soft skills. From `data/profile.json`.
- **Achievements** — rendering challenge placements. From `data/profile.json`.

```
portfolio/
  index.html
  css/style.css
  js/app.js
  img/
    favicon-16.png, favicon-32.png, favicon-48.png  ← browser tab icon
    apple-touch-icon.png                              ← iOS home-screen icon
    favicon-512.png                                    ← master, for regenerating other sizes
  data/profile.json      ← work history, skills, achievements, education, languages
  projects.json          ← list of project folder names, in any order
  projects/
    <slug>/
      info.txt           ← the project's text file (no images)
```

## Editing your work history, skills or achievements

All of that lives in `data/profile.json` — a plain JSON file with `experience`, `skills`, `achievements`, `education` and `languages`. Add, remove, or reorder entries directly; the page re-renders whatever's there. This is separate from the `projects/` folders on purpose — your job history doesn't grow the same way your project list does.

Note: BINYAN's portfolio highlights (Armani Residences Diriyah, One Harbor Shore Drive, etc.) are handled as a `links` array on that job entry in `profile.json`, rendered as plain clickable links under the role — not as full project cards, since you can't share images/links for client work directly. Swap in real URLs as you get them; anything without a confirmed page currently points at binyanstudios.com as a fallback.

## Adding a new project

1. Duplicate any folder in `projects/`, rename it to a short slug (e.g. `my-new-app`).
2. Edit its `info.txt`:
   ```
   title: My New App
   category: Tool
   date: 2026
   description: One or two sentences about the project.
   tags: JavaScript, Supabase
   link: Live site | https://example.com
   ```
   - `link:` can repeat (one per line) if you have more than one URL — e.g. one for the live app, one for the source code.
   - `tags:` is comma-separated.
   - Lines starting with `#` are ignored — handy for notes or a link you haven't filled in yet.
   - No image files needed — each project renders as a plain text card (category, date, title, description, tags, links).
3. Add the folder's slug to `projects.json`. That's the only "code" file you touch.

Categories are whatever you type after `category:` — the filter bar at the top builds itself from whatever categories exist across your projects, so introducing a new one (e.g. `Photography`) just works.

## Render gallery (standalone images, not tied to a project)

There's a separate "Render gallery" section for stills that don't belong to any one project.

```
portfolio/
  gallery/
    generate_manifest.py  ← run this after adding/removing images
    gallery.json           ← auto-generated list, don't hand-edit the file list
    01.jpg, 02.jpg...       ← your actual image files, any names you like
```

1. **Upload your images into `portfolio/gallery/`** (any filenames — `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`, `.avif` are all picked up).
2. Run:
   ```
   python3 gallery/generate_manifest.py
   ```
   This scans the folder and rewrites `gallery.json` for you, newest first — sorted by filename in reverse order. Prefix filenames with a year/date (e.g. `2026-lobby.jpg`, `2024-facade.jpg`) so the newest renders sort to the top. Re-run it whenever you add, remove, or rename images.
3. Optional: open `gallery.json` afterwards and fill in a `caption` for any image if you want one — the script preserves existing captions the next time you run it, it only adds new files and drops missing ones.
4. Click any thumbnail on the live site to open it full-size, with arrow-key/click navigation between images.

**Note for static hosts (Netlify/Vercel/GitHub Pages):** the site can't scan the folder itself at runtime — that's why the script exists. If you want it to happen automatically on every deploy, you can set your host's build command to `python3 gallery/generate_manifest.py` (Python 3 needs to be available in the build environment) instead of running it locally.

## Previewing locally

Browsers block `fetch()` on files opened directly from disk (`file://`), so run a tiny local server from the `portfolio/` folder:

```
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

## Deploying

It's fully static — drag the `portfolio/` folder into Netlify/Vercel, or push it to a GitHub repo and turn on GitHub Pages. No config needed.

## What's already in here

Three sample projects seeded from your CV (TraceTheBreak, TraceTheToxin, StrTools), rendered as plain text/link cards. AR-TY is kept as a work-history entry under Where I've Worked rather than a project folder. BINYAN's archviz highlights are handled the same way, as links under the BINYAN entry in Where I've Worked (see above).

I couldn't pull anything from your LinkedIn directly (it's behind a login wall) — paste the links/descriptions here and I'll turn them into folders, or you can fill them in yourself following the pattern above.
