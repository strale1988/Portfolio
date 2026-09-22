// ---------------------------------------------------------------
// Always start at the top of the page, even on refresh with a
// scroll position or hash the browser would otherwise restore.
// ---------------------------------------------------------------
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}
window.scrollTo(0, 0);
window.addEventListener('load', () => window.scrollTo(0, 0));

// ---------------------------------------------------------------
// Keep the page feeling "clean" — no right-click save/inspect menu,
// no dragging images out, no accidental text selection from stray
// clicks. CSS (user-select/user-drag) already blocks most of it;
// this covers the couple of things CSS can't.
// ---------------------------------------------------------------
document.addEventListener('contextmenu', (e) => e.preventDefault());
document.addEventListener('dragstart', (e) => e.preventDefault());

// ---------------------------------------------------------------
// Theme toggle. The initial theme is set inline in <head> (before
// paint, to avoid a flash); this just wires up the button to flip
// and persist it.
// ---------------------------------------------------------------
function initThemeToggle() {
  const btn = document.getElementById('theme-toggle');
  if (!btn) return;

  btn.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
    const next = current === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    document.dispatchEvent(new CustomEvent('themechange', { detail: { theme: next } }));
  });
}

initThemeToggle();

// ---------------------------------------------------------------
// Minimal scroll-triggered reveal. Uses IntersectionObserver (not a
// scroll listener) and only touches opacity/transform, so it's
// cheap and can't cause the layout jitter the old scroll effect had.
// Call markReveal(el) when creating an element, then observeReveal()
// once it's in the DOM.
// ---------------------------------------------------------------
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('is-visible');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });

function markReveal(el, index = 0) {
  el.classList.add('reveal');
  if (index) el.style.setProperty('--reveal-delay', `${Math.min(index, 5) * 70}ms`);
  return el;
}

function observeReveal(root = document) {
  root.querySelectorAll('.reveal:not(.is-visible)').forEach(el => revealObserver.observe(el));
}

// ---------------------------------------------------------------
// Scroll-progress threshold for the header text fade (how far
// through the hero's own height you've scrolled before the hero
// text is fully faded out — see initHeaderParallax).
// ---------------------------------------------------------------
const HEADER_SCROLL = {
  TEXT_FADE_END: 0.45
};

// ---------------------------------------------------------------
// Header parallax: as you scroll through the hero, the text drifts
// upward and fades out completely well before you've scrolled a
// full hero-height (see HEADER_SCROLL.TEXT_FADE_END). Driven by a
// throttled scroll listener and only ever writes transform/opacity
// (compositor-only, no layout reads of anything that changes shape)
// — safe from the jitter the old height-driven effect had.
// ---------------------------------------------------------------
function initHeaderParallax() {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

  const hero = document.querySelector('.hero-content');
  const hud = document.querySelector('.hud');
  if (!hero || !hud) return;

  const heroReadouts = document.querySelectorAll('.hud-readout');
  let ticking = false;

  function update() {
    const range = hud.offsetHeight; // fixed 100vh, doesn't change with scroll
    const scrolled = Math.min(window.scrollY, range);
    const progress = scrolled / range;

    // Text drifts down relative to the page as you scroll — since the
    // page itself is already moving everything up 1:1, adding a partial
    // downward offset here makes the text lag behind, i.e. feel like it
    // scrolls slower than the rest of the header.
    hero.style.transform = `translateY(${scrolled * 0.35}px)`;

    // Fully faded out by TEXT_FADE_END rather than fading gradually
    // across the whole hero, so it's out of the way before the
    // background image starts appearing.
    const textOpacity = 1 - Math.min(progress / HEADER_SCROLL.TEXT_FADE_END, 1);
    hero.style.opacity = String(textOpacity);

    heroReadouts.forEach(el => {
      el.style.opacity = String(textOpacity);
    });

    ticking = false;
  }

  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(update);
      ticking = true;
    }
  }, { passive: true });

  update();
}

// ---------------------------------------------------------------
// Full-site preloader. Waits for the window 'load' event (all
// images, fonts and the grid canvas's first paint are ready by
// then) with a short minimum display time so it never just flashes
// on a fast connection, then fades it out and removes it from the
// DOM so it can't block clicks or show up in the accessibility tree.
// ---------------------------------------------------------------
function initSitePreloader() {
  const el = document.getElementById('site-preloader');
  if (!el) return;

  const MIN_DISPLAY_MS = 500;
  const shownAt = performance.now();

  function hide() {
    const elapsed = performance.now() - shownAt;
    const wait = Math.max(0, MIN_DISPLAY_MS - elapsed);
    setTimeout(() => {
      el.classList.add('preloader-hidden');
      el.addEventListener('transitionend', () => el.remove(), { once: true });
      // Fallback in case transitionend doesn't fire (e.g. display:none elsewhere).
      setTimeout(() => el.remove(), 700);
    }, wait);
  }

  if (document.readyState === 'complete') {
    hide();
  } else {
    window.addEventListener('load', hide, { once: true });
  }
  // Absolute fallback: never let a stalled resource keep it up forever.
  setTimeout(hide, 4000);
}

initSitePreloader();

initHeaderParallax();

// ---------------------------------------------------------------
// Back-to-top button: fades in once you've scrolled past one
// viewport height, scrolls smoothly back to the top on click.
// ---------------------------------------------------------------
function initBackToTop() {
  const btn = document.getElementById('back-to-top');
  if (!btn) return;

  const THRESHOLD = window.innerHeight;
  let ticking = false;

  function update() {
    btn.classList.toggle('visible', window.scrollY > THRESHOLD);
    ticking = false;
  }

  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(update);
      ticking = true;
    }
  }, { passive: true });

  btn.addEventListener('click', () => {
    window.scrollTo({
      top: 0,
      behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth',
    });
  });

  update();
}

initBackToTop();

// ---------------------------------------------------------------
// Active section highlighting: marks the nav link for whichever
// section currently occupies the middle band of the viewport.
// IntersectionObserver-based (not a scroll listener) so it stays
// cheap and doesn't fight with the reveal-on-scroll observer.
// ---------------------------------------------------------------
function initActiveNav() {
  const navLinks = Array.from(document.querySelectorAll('.site-nav a[href^="#"]'));
  if (!navLinks.length) return;

  const sections = navLinks
    .map(a => document.querySelector(a.getAttribute('href')))
    .filter(Boolean);
  if (!sections.length) return;

  const linkFor = (id) => navLinks.find(a => a.getAttribute('href') === `#${id}`);

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const link = linkFor(entry.target.id);
      if (!link) return;
      if (entry.isIntersecting) {
        navLinks.forEach(a => a.classList.remove('active'));
        link.classList.add('active');
      }
    });
  }, {
    // Counts a section as "current" once it's crossed the middle
    // of the viewport, and stops counting once it's mostly scrolled
    // past — a band around the vertical center rather than the
    // whole section, so long sections don't stay "active" for ages.
    rootMargin: '-45% 0px -45% 0px',
    threshold: 0,
  });

  sections.forEach(s => observer.observe(s));
}

initActiveNav();

// ---------------------------------------------------------------
// Site-wide grid: one canvas, fixed to the viewport, behind the
// whole page (the hero included: .hud has no background of its
// own, so this shows straight through it). What happens here:
//
//  1. Row placement is solved at runtime so no horizontal line
//     ever cuts across the hero heading/subhead/meta/location text:
//     it searches nearby cell sizes + vertical offsets and keeps
//     whichever one (closest to the default size) clears every
//     line of hero text, recomputed on resize/font-load/theme change.
//  2. Every active pointer (mouse, pen, or a finger per touch) gets
//     its own glow that eases toward it and brightens with how fast
//     it's moving.
//  3. Random cells across the grid quietly light up and fade on
//     their own the whole time, so the background never looks inert.
//  4. The grid drifts slowly as the page scrolls — a subtle
//     parallax at SCROLL_PARALLAX (25% of actual scroll speed), so
//     it feels like it sits behind the content rather than
//     scrolling in lockstep with it. Grid lines, the ambient
//     flickers and the pointer glow are all drawn in this same
//     scroll-shifted ("virtual") coordinate space via a single
//     ctx.translate, so they stay aligned with each other and with
//     the cell the pointer is actually over.
//
// Respects prefers-reduced-motion by keeping the (still correctly
// aligned) static grid but skipping all pointer-driven and
// scroll-driven animation.
// ---------------------------------------------------------------
function initSiteGrid() {
  const canvas = document.querySelector('.site-grid');
  if (!canvas || !canvas.getContext) return;

  const ctx = canvas.getContext('2d');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const DEFAULT_CELL = 40;
  const MIN_CELL = 30;
  const MAX_CELL = 56;
  const TEXT_CLEARANCE = 6; // breathing room (px) kept around each text line
  const FLICKER_DURATION = 900; // ms
  const FLICKER_MIN_GAP = 500; // ms between ambient flickers
  const FLICKER_MAX_GAP = 1600;
  const SCROLL_PARALLAX = 0.25; // grid moves at 25% of actual scroll speed

  let cssWidth = 0, cssHeight = 0;
  let cell = DEFAULT_CELL, rowOffset = 0;
  let lineColor = 'rgba(0,0,0,0.05)';
  let lastFrameTime = 0;
  let scrollOffset = reduceMotion ? 0 : window.scrollY * SCROLL_PARALLAX;

  function readColor() {
    lineColor = getComputedStyle(document.documentElement).getPropertyValue('--grid-line').trim() || lineColor;
  }

  function hasClash(candidateCell, offset, bands) {
    for (let y = offset; y < cssHeight; y += candidateCell) {
      for (const [top, bottom] of bands) {
        if (y >= top && y <= bottom) return true;
      }
    }
    return false;
  }

  // Search for the cell size (closest to DEFAULT_CELL) + vertical
  // offset where no horizontal line lands inside any hero text box.
  // Hero elements are only near the top of the page, so this only
  // ever matters while the hero is (or was, at last resize) in view.
  function solveRowLayout() {
    const heroEls = document.querySelectorAll('.hero-content > *');
    if (!heroEls.length) return { cell: DEFAULT_CELL, offset: 0 };

    const bands = Array.from(heroEls).map(el => {
      const r = el.getBoundingClientRect();
      return [r.top - TEXT_CLEARANCE, r.bottom + TEXT_CLEARANCE];
    });

    for (let c = DEFAULT_CELL; c <= MAX_CELL; c++) {
      for (let offset = 0; offset < c; offset += 2) {
        if (!hasClash(c, offset, bands)) return { cell: c, offset };
      }
    }
    for (let c = DEFAULT_CELL - 1; c >= MIN_CELL; c--) {
      for (let offset = 0; offset < c; offset += 2) {
        if (!hasClash(c, offset, bands)) return { cell: c, offset };
      }
    }
    return { cell: DEFAULT_CELL, offset: 0 };
  }

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    cssWidth = window.innerWidth;
    cssHeight = window.innerHeight;
    canvas.width = Math.round(cssWidth * dpr);
    canvas.height = Math.round(cssHeight * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const layout = solveRowLayout();
    cell = layout.cell;
    rowOffset = layout.offset;
    readColor();
    drawStatic();
  }

  function hexToRgba(hex, alpha) {
    let h = hex.replace('#', '');
    if (h.length === 3) h = h.split('').map(c => c + c).join('');
    const num = parseInt(h, 16);
    if (Number.isNaN(num)) return `rgba(20,150,140,${alpha})`;
    return `rgba(${(num >> 16) & 255},${(num >> 8) & 255},${num & 255},${alpha})`;
  }

  // ---- interaction state -----------------------------------------
  // One glow per active input (mouse/pen keyed 'mouse', each finger
  // keyed by its touch identifier), plus ambient flickers. Both are
  // just objects that fade in/out over time; the render loop keeps
  // running only while at least one of them is still alive.
  const pointers = new Map();
  const flickers = [];
  let rafId = null;
  let flickerTimerId = null;

  function getPointer(id) {
    let p = pointers.get(id);
    if (!p) {
      p = { x: -9999, y: -9999, drawX: -9999, drawY: -9999, prevDrawX: -9999, prevDrawY: -9999,
             strength: 0, target: 0, speed: 0 };
      pointers.set(id, p);
    }
    return p;
  }

  function moveGlow(id, x, y) {
    const isNew = !pointers.has(id);
    const p = getPointer(id);
    p.x = x;
    p.y = y;
    // A pointer that has just appeared starts life parked off-screen,
    // so easing it in would fling a bright glow across the viewport
    // from the corner on every new touch. Snap it to where the input
    // actually is instead, and zero the speed so it doesn't read as a
    // fast flick on its first frame.
    if (isNew) {
      p.drawX = p.prevDrawX = x;
      p.drawY = p.prevDrawY = y;
      p.speed = 0;
    }
    p.target = 1;
    ensureLoop();
  }

  function releaseGlow(id) {
    const p = pointers.get(id);
    if (p) p.target = 0;
    ensureLoop();
  }

  // Random cells across the grid light up and fade on their own,
  // continuously, regardless of whether anything is being dragged.
  function scheduleFlicker() {
    if (!reduceMotion && document.visibilityState === 'visible') {
      const cols = Math.max(1, Math.floor(cssWidth / cell));
      const rows = Math.max(1, Math.floor((cssHeight - rowOffset) / cell));
      const col = Math.floor(Math.random() * cols);
      const row = Math.floor(Math.random() * rows);
      flickers.push({
        x: col * cell + cell / 2,
        y: rowOffset + row * cell + cell / 2 + scrollOffset,
        start: performance.now(),
      });
      ensureLoop();
    }
    flickerTimerId = setTimeout(scheduleFlicker, FLICKER_MIN_GAP + Math.random() * (FLICKER_MAX_GAP - FLICKER_MIN_GAP));
  }

  function ensureLoop() {
    if (!rafId && !reduceMotion) rafId = requestAnimationFrame(loop);
  }

  function loop(now) {
    rafId = null;
    const dt = lastFrameTime ? Math.min(now - lastFrameTime, 64) : 16;
    lastFrameTime = now;

    let stillActive = false;

    for (const [id, p] of pointers) {
      p.strength += (p.target - p.strength) * 0.18;
      p.prevDrawX = p.drawX;
      p.prevDrawY = p.drawY;
      p.drawX += (p.x - p.drawX) * 0.25;
      p.drawY += (p.y - p.drawY) * 0.25;

      const dist = Math.hypot(p.drawX - p.prevDrawX, p.drawY - p.prevDrawY);
      const instSpeed = dt > 0 ? dist / dt : 0; // px/ms
      p.speed += (instSpeed - p.speed) * 0.3;

      const settledStrength = Math.abs(p.strength - p.target) < 0.01;
      const settledPos = Math.hypot(p.x - p.drawX, p.y - p.drawY) < 0.5;
      if (p.target === 0 && settledStrength) {
        pointers.delete(id);
      } else if (!settledStrength || !settledPos) {
        stillActive = true;
      }
    }

    const flickerAlive = flickers.length > 0;

    draw(now);

    if (stillActive || flickerAlive) rafId = requestAnimationFrame(loop);
  }

  function fillCell(col, row, alpha, accentRgba) {
    if (alpha <= 0.003) return;
    ctx.fillStyle = accentRgba(alpha);
    ctx.fillRect(col * cell, rowOffset + row * cell, cell, cell);
  }

  function draw(now) {
    ctx.clearRect(0, 0, cssWidth, cssHeight);

    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';
    const tealHex = getComputedStyle(document.documentElement).getPropertyValue('--teal').trim();
    const tealRgba = (a) => hexToRgba(tealHex, a);
    const baseGlowAlpha = isDark ? 0.22 : 0.14;

    // Everything below is drawn in "virtual" (scroll-shifted) space:
    // translating the context by -scrollOffset once here means grid
    // lines, the pointer glow and the ambient flicker can all just
    // use their normal rowOffset-relative coordinates and land in
    // the right place on screen, already aligned with each other.
    ctx.save();
    ctx.translate(0, -scrollOffset);

    // Base grid, straight and cheap. Lines are drawn across the
    // full virtual range the viewport currently covers (scrollOffset
    // to scrollOffset + cssHeight), not just 0..cssHeight, since the
    // translate has shifted what "on screen" means in this space.
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x <= cssWidth + 1; x += cell) {
      ctx.moveTo(Math.round(x) + 0.5, scrollOffset);
      ctx.lineTo(Math.round(x) + 0.5, scrollOffset + cssHeight);
    }
    const firstLineY = rowOffset + Math.floor((scrollOffset - rowOffset) / cell) * cell;
    for (let y = firstLineY; y <= scrollOffset + cssHeight + cell; y += cell) {
      ctx.moveTo(0, Math.round(y) + 0.5);
      ctx.lineTo(cssWidth, Math.round(y) + 0.5);
    }
    ctx.stroke();

    for (const p of pointers.values()) {
      if (p.strength <= 0.01) continue;

      // Velocity-reactive main glow: faster movement = bigger, brighter.
      const speedBoost = Math.min(p.speed / 1.2, 1); // 0..1
      const reach = cell * (1.6 + speedBoost * 0.9);
      const strengthMult = 1 + speedBoost * 0.6;

      // The pointer's own position is a fixed point on screen (it
      // doesn't move when the page scrolls), so it's converted into
      // the same virtual space as the grid before picking a cell.
      const pointerVirtualY = p.drawY + scrollOffset;
      const col = Math.floor(p.drawX / cell);
      const row = Math.floor((pointerVirtualY - rowOffset) / cell);
      const spread = speedBoost > 0.5 ? 2 : 1;

      for (let dr = -spread; dr <= spread; dr++) {
        for (let dc = -spread; dc <= spread; dc++) {
          const cx = (col + dc) * cell;
          const cy = rowOffset + (row + dr) * cell;
          const dist = Math.hypot(cx + cell / 2 - p.drawX, cy + cell / 2 - pointerVirtualY);
          const falloff = Math.max(0, 1 - dist / reach);
          if (falloff <= 0) continue;
          const alpha = falloff * p.strength * baseGlowAlpha * strengthMult;
          if (alpha <= 0.003) continue;
          ctx.fillStyle = tealRgba(alpha);
          ctx.fillRect(cx, cy, cell, cell);
        }
      }
    }

    // Ambient flicker: a single cell softly breathing in/out. Each
    // flicker's y was recorded in virtual space at the moment it was
    // scheduled, so it naturally drifts along with the grid if the
    // page keeps scrolling during its short lifetime.
    for (let i = flickers.length - 1; i >= 0; i--) {
      const f = flickers[i];
      const age = now - f.start;
      if (age > FLICKER_DURATION) { flickers.splice(i, 1); continue; }
      const t = age / FLICKER_DURATION;
      const alpha = Math.sin(t * Math.PI) * baseGlowAlpha * 0.8;
      const col = Math.floor(f.x / cell);
      const row = Math.floor((f.y - rowOffset) / cell);
      fillCell(col, row, alpha, tealRgba);
    }

    ctx.restore();
  }

  function drawStatic() {
    draw(performance.now());
  }

  // ---- input wiring ------------------------------------------------
  // Pointer events cover mouse/pen. Touch is handled separately (see
  // the note above initSiteGrid): mobile browsers don't reliably keep
  // dispatching pointermove for a touch that's also driving a page
  // scroll, so real touch events are what makes the glow follow a
  // dragging finger, and pointer events with pointerType 'touch' are
  // ignored here to avoid tracking the same finger twice.
  function onPointerMove(e) {
    if (e.pointerType === 'touch') return;
    moveGlow('mouse', e.clientX, e.clientY);
  }
  function onPointerDown(e) {
    if (e.pointerType === 'touch') return;
    moveGlow('mouse', e.clientX, e.clientY);
  }
  function onPointerLeave(e) {
    if (e.pointerType === 'touch') return;
    releaseGlow('mouse');
  }
  function onTouchStart(e) {
    for (const t of e.changedTouches) {
      moveGlow(`touch-${t.identifier}`, t.clientX, t.clientY);
    }
  }
  function onTouchMove(e) {
    for (const t of e.touches) {
      moveGlow(`touch-${t.identifier}`, t.clientX, t.clientY);
    }
  }
  function onTouchEnd(e) {
    for (const t of e.changedTouches) {
      releaseGlow(`touch-${t.identifier}`);
    }
  }

  window.addEventListener('pointermove', onPointerMove, { passive: true });
  window.addEventListener('pointerdown', onPointerDown, { passive: true });
  window.addEventListener('pointerleave', onPointerLeave);
  window.addEventListener('touchstart', onTouchStart, { passive: true });
  window.addEventListener('touchmove', onTouchMove, { passive: true });
  window.addEventListener('touchend', onTouchEnd, { passive: true });
  window.addEventListener('touchcancel', onTouchEnd, { passive: true });
  window.addEventListener('resize', resize);
  document.fonts?.ready?.then(resize);
  new MutationObserver(resize).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });

  // Grid parallax: redraws on scroll so the grid visibly drifts at
  // SCROLL_PARALLAX of actual scroll speed, independent of the
  // pointer/flicker animation loop (which only runs while something
  // is actively animating).
  if (!reduceMotion) {
    let scrollTicking = false;
    window.addEventListener('scroll', () => {
      if (!scrollTicking) {
        requestAnimationFrame(() => {
          scrollOffset = window.scrollY * SCROLL_PARALLAX;
          draw(performance.now());
          scrollTicking = false;
        });
        scrollTicking = true;
      }
    }, { passive: true });
  }

  resize();
  if (!reduceMotion) {
    flickerTimerId = setTimeout(scheduleFlicker, FLICKER_MIN_GAP + Math.random() * (FLICKER_MAX_GAP - FLICKER_MIN_GAP));
  }
}

initSiteGrid();

// ---------------------------------------------------------------
// Work: one grid for stills, animations and apps.
//
// Two sources, normalised into the same "item" shape:
//   gallery/gallery.json                        stills + videos
//                                               (kept up to date by generate_manifest.py)
//   projects.json + projects/<slug>/info.txt    apps & tools
//
// Every item ends up with:
//   kind      'media' | 'app'
//   category  'visualization' | 'animation' | 'app'
//   year      from the filename prefix (media) or `date:` (apps)
//   featured  false | true | a position number (1 = first in its view)
//
// The chips above the grid are different views over that list:
//   Visualization / Animation / Apps & Tools    one category each. Items with a
//                       `featured` number are pinned first, in that order; the
//                       rest follow, newest first.
//   Archive             everything, strictly newest first, under year headings
// ---------------------------------------------------------------

const WORK_PAGE_SIZE = 18; // divisible by 2 and 3, so rows fill on every layout
const WORK_VIDEO_EXTENSIONS = ['mp4', 'webm', 'mov', 'm4v'];

// NDA-covered work lives in its own subfolder so it can be kept/rotated
// separately from the public gallery assets. To save space, every NDA
// item shares one placeholder image (nda_images/NDA.webp) rather than
// its own file — the original per-item filename in gallery.json is kept
// only for year-sorting/grouping, not for the actual image served.
function galleryPath(filename) {
  return filename.includes('NDA') ? 'gallery/nda_images/NDA.webp' : `gallery/${filename}`;
}

const WORK_FILTERS = [
  { id: 'visualization', label: 'Visualization', sub: 'Architectural stills and renders.',                  test: it => it.category === 'visualization' },
  { id: 'animation',     label: 'Animation',     sub: 'Animations and turntables.',                         test: it => it.category === 'animation' },
  { id: 'app',           label: 'Apps & Tools',  sub: 'Interactive apps, web tools and experiences.',       test: it => it.category === 'app' },
  { id: 'archive',       label: 'Archive',       sub: 'Everything, newest first.',                          test: () => true, byYear: true }
];

let workItems = [];       // every item, newest first
let workView = [];        // items matching the active chip
let workMedia = [];       // the image/video subset of workView (what the lightbox steps through)
let workShown = 0;        // how many of workView are on screen
let workFilter = 'archive';
let workLastYear = null;  // last year heading drawn (Archive only)
let workLightboxIndex = 0;

// One observer for every grid video: play while visible, pause when not.
// Shared (and disconnected on each re-render) so switching chips doesn't
// leave a pile of old observers behind.
const workVideoObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) entry.target.play().catch(() => {});
    else entry.target.pause();
  });
}, { threshold: 0.4 });

// ---- data loading ----------------------------------------------

function fileExt(file) {
  const match = /\.([a-z0-9]+)$/i.exec(file || '');
  return match ? match[1].toLowerCase() : '';
}

// "2024_Forest House.webp" -> 2024. No prefix -> 0 (shown as "Undated", sorted last).
function yearFromFilename(file) {
  const match = /^(\d{4})/.exec(file || '');
  return match ? parseInt(match[1], 10) : 0;
}

// Pulls a sortable year out of a date string like "2024" or "2019-2023".
function sortYear(dateStr) {
  const match = (dateStr || '').match(/\d{4}/g);
  return match ? parseInt(match[match.length - 1], 10) : 0;
}

// `featured: 3` -> pinned at position 3, `featured: yes` -> pinned after the numbered ones, else false.
function parseFeatured(value) {
  const v = value.trim().toLowerCase();
  if (/^\d+$/.test(v)) return parseInt(v, 10) || false;
  return ['yes', 'true', 'y'].includes(v);
}

async function loadGalleryItems() {
  const res = await fetch('gallery/gallery.json');
  if (!res.ok) throw new Error('Could not load gallery/gallery.json');
  const raw = await res.json();
  return raw.map(entry => {
    const e = typeof entry === 'string' ? { file: entry } : entry;
    const media = e.type === 'video' || e.type === 'image'
      ? e.type
      : (WORK_VIDEO_EXTENSIONS.includes(fileExt(e.file)) ? 'video' : 'image');
    // Category follows the file type; an optional "category" in gallery.json
    // can override it (e.g. an animation frame you want under Animation).
    // A category of "archive" (or anything else outside the two normal
    // categories) deliberately matches no chip's test but still passes the
    // Archive chip's `() => true`, so the item shows there only.
    const category = e.category
      ? e.category
      : (media === 'video' ? 'animation' : 'visualization');
    return {
      kind: 'media',
      media,
      category,
      file: e.file,
      caption: e.caption || '',
      poster: e.poster || '',
      featured: e.featured || false,
      year: e.year || yearFromFilename(e.file)
    };
  });
}

// Parses the simple "key: value" info.txt format.
// - Lines starting with # are comments.
// - `link:` may repeat; format is "Label | https://url".
// - `tags:` is a comma separated list.
// - `cover:` is an image inside the project's folder (e.g. cover.webp).
// - `featured:` is yes, or a number to rank it within Selected.
function parseInfo(raw, slug) {
  const project = { slug, title: slug, category: '', date: '', description: '', cover: '', featured: false, tags: [], links: [] };
  const lines = raw.split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf(':');
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim().toLowerCase();
    const value = trimmed.slice(idx + 1).trim();
    switch (key) {
      case 'title': project.title = value; break;
      case 'category': project.category = value; break;
      case 'date': project.date = value; break;
      case 'description': project.description = value; break;
      case 'cover': project.cover = value; break;
      case 'featured': project.featured = parseFeatured(value); break;
      case 'tags': project.tags = value.split(',').map(s => s.trim()).filter(Boolean); break;
      case 'link': {
        const [label, url] = value.split('|').map(s => s.trim());
        if (url) project.links.push({ label: label || url, url });
        break;
      }
      default: break;
    }
  }
  return project;
}

async function loadProject(slug) {
  const res = await fetch(`projects/${slug}/info.txt`);
  if (!res.ok) throw new Error(`Missing info.txt for ${slug}`);
  return parseInfo(await res.text(), slug);
}

// Everything listed in projects.json is an app/tool. A project with a
// broken or missing info.txt is skipped instead of taking the rest down.
async function loadAppItems() {
  const res = await fetch('projects.json');
  if (!res.ok) throw new Error('Could not load projects.json');
  const slugs = await res.json();
  const projects = await Promise.all(
    slugs.map(slug => loadProject(slug).catch(err => { console.warn(err); return null; }))
  );
  return projects.filter(Boolean).map(p => ({
    kind: 'app',
    category: 'app',
    slug: p.slug,
    title: p.title,
    label: p.category,   // the free-text category from info.txt, shown on the card
    date: p.date,
    year: sortYear(p.date),
    description: p.description,
    tags: p.tags,
    links: p.links,
    cover: p.cover ? `projects/${p.slug}/${p.cover}` : '',
    featured: p.featured
  }));
}

// ---- cards -----------------------------------------------------

// Makes a div behave like a button for keyboard users: focusable,
// announced correctly, and activated by Enter or Space — same as
// the click handler already wired up on it.
function makeActivatable(el, label) {
  el.tabIndex = 0;
  el.setAttribute('role', 'button');
  if (label) el.setAttribute('aria-label', label);
  el.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      el.click();
    }
  });
}

function buildMediaCard(item) {
  const card = document.createElement('div');
  card.className = 'gallery-item' + (item.media === 'video' ? ' is-video' : '');

  if (item.media === 'video') {
    const posterAttr = item.poster ? ` poster="${galleryPath(item.poster)}"` : '';
    card.innerHTML = `<video src="${galleryPath(item.file)}"${posterAttr} muted loop playsinline preload="metadata" aria-label="${item.caption || 'Animation'}"></video>`;
    const video = card.querySelector('video');
    video.onerror = function () { card.remove(); };
    // "metadata" preload alone leaves most browsers showing a blank
    // black frame until playback starts. Nudging the playhead a
    // fraction of a second in once the metadata is in forces the
    // browser to decode and paint that frame as a thumbnail, without
    // downloading the rest of the file.
    video.addEventListener('loadedmetadata', () => {
      if (!item.poster) video.currentTime = Math.min(0.1, (video.duration || 1) / 2);
    }, { once: true });
    workVideoObserver.observe(video);
  } else {
    card.innerHTML = `<img src="${galleryPath(item.file)}" alt="${item.caption || 'Render'}" loading="lazy">`;
    card.querySelector('img').onerror = function () { card.remove(); };
  }

  card.addEventListener('click', () => openLightbox(workMedia.indexOf(item)));
  makeActivatable(card, item.caption ? `Open ${item.caption}` : (item.media === 'video' ? 'Open animation' : 'Open render'));
  return card;
}

// Apps sit in the same 4:3 cell as the stills and open a detail panel on
// click (full description, tech tags, links). With a `cover:` the image
// fills the cell with a caption strip along the bottom; without one the
// cell is a typographic tile (category + date, title, tech tags).
function appMeta(item) {
  return [item.label || 'App', item.date].filter(Boolean).join(' · ');
}

function appTags(item) {
  return item.tags.length
    ? `<div class="tag-list">${item.tags.map(t => `<span class="tag">${t}</span>`).join('')}</div>`
    : '';
}

function appTileHtml(item) {
  return `<div class="app-tile">
      <p class="app-meta">${appMeta(item)}</p>
      <h3>${item.title}</h3>
      ${appTags(item)}
    </div>`;
}

function buildAppCard(item) {
  const card = document.createElement('div');
  card.className = 'gallery-item is-app' + (item.cover ? '' : ' no-cover');

  if (item.cover) {
    card.innerHTML = `<img src="${item.cover}" alt="${item.title}" loading="lazy">
      <div class="app-caption"><p class="app-meta">${appMeta(item)}</p><h3>${item.title}</h3></div>`;
    // Missing cover file? Fall back to the tile instead of a broken image.
    card.querySelector('img').onerror = function () {
      card.classList.add('no-cover');
      card.innerHTML = appTileHtml(item);
    };
  } else {
    card.innerHTML = appTileHtml(item);
  }

  card.addEventListener('click', () => openAppDetail(item));
  makeActivatable(card, `Open details: ${item.title}`);
  return card;
}

// ---- app detail panel ------------------------------------------

let appDetailReturnFocus = null;

function openAppDetail(item) {
  const overlay = document.getElementById('app-detail');
  const cover = document.getElementById('app-detail-cover');

  if (item.cover) {
    cover.hidden = false;
    cover.alt = item.title;
    cover.onerror = function () { cover.hidden = true; };
    cover.src = item.cover;
  } else {
    cover.hidden = true;
    cover.removeAttribute('src');
  }

  const links = item.links.length
    ? `<div class="links-row">${item.links.map(l => `<a href="${l.url}" target="_blank" rel="noopener">${l.label} ↗</a>`).join('')}</div>`
    : '';
  document.getElementById('app-detail-body').innerHTML = `
    <p class="app-meta">${appMeta(item)}</p>
    <h3 id="app-detail-title">${item.title}</h3>
    ${item.description ? `<p class="app-detail-desc">${item.description}</p>` : ''}
    ${appTags(item)}
    ${links}`;

  appDetailReturnFocus = document.activeElement;
  overlay.classList.add('open');
  overlay.setAttribute('aria-hidden', 'false');
  document.getElementById('app-detail-close').focus();
}

function closeAppDetail() {
  const overlay = document.getElementById('app-detail');
  overlay.classList.remove('open');
  overlay.setAttribute('aria-hidden', 'true');
  if (appDetailReturnFocus && appDetailReturnFocus.focus) appDetailReturnFocus.focus();
  appDetailReturnFocus = null;
}

function initAppDetail() {
  const overlay = document.getElementById('app-detail');
  if (!overlay) return;
  document.getElementById('app-detail-close').addEventListener('click', closeAppDetail);
  overlay.addEventListener('click', (e) => { if (e.target === overlay) closeAppDetail(); });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && overlay.classList.contains('open')) closeAppDetail();
  });
}

// ---- filters, grid, paging -------------------------------------

function buildWorkFilters() {
  const nav = document.getElementById('filters');
  nav.innerHTML = '';

  // Only offer chips that would actually show something (Archive always does).
  const chips = WORK_FILTERS.filter(f => f.id === 'archive' || workItems.some(f.test));
  chips.forEach(f => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'filter-chip';
    btn.dataset.filter = f.id;
    btn.textContent = f.label;
    btn.addEventListener('click', () => setWorkFilter(f.id));
    nav.appendChild(btn);
  });

  // Open on the first chip (Visualization).
  setWorkFilter(chips[0].id);
}

function setWorkFilter(id) {
  const def = WORK_FILTERS.find(f => f.id === id);
  workFilter = id;

  document.querySelectorAll('#filters .filter-chip').forEach(chip => {
    const on = chip.dataset.filter === id;
    chip.classList.toggle('active', on);
    chip.setAttribute('aria-pressed', String(on));
  });
  const sub = document.getElementById('work-sub');
  if (sub) sub.textContent = def.sub;

  workView = workItems.filter(def.test);
  if (!def.byYear) {
    // Pinned items first: numbered ones in order (1, 2, 3...), then anything
    // marked true/yes, then everything else in its existing newest-first order
    // (Array.sort is stable). Archive skips this: it's strictly chronological.
    const rank = it => (typeof it.featured === 'number' ? it.featured : (it.featured ? 1e6 : Number.MAX_SAFE_INTEGER));
    workView.sort((a, b) => rank(a) - rank(b));
  }
  workMedia = workView.filter(it => it.kind === 'media');

  renderWorkGrid();
}

function renderWorkGrid() {
  const grid = document.getElementById('work-grid');
  workVideoObserver.disconnect();
  grid.innerHTML = '';
  workShown = 0;
  workLastYear = null;

  if (!workView.length) {
    grid.innerHTML = '<p class="loading">Nothing here yet.</p>';
    updateWorkSentinel();
    return;
  }
  appendWorkBatch();
}

// Appends the next page of the active view without touching what's
// already on screen, adding a year heading whenever the year changes
// (Archive only).
function appendWorkBatch() {
  const grid = document.getElementById('work-grid');
  const byYear = WORK_FILTERS.find(f => f.id === workFilter).byYear;
  const batch = workView.slice(workShown, workShown + WORK_PAGE_SIZE);

  batch.forEach((item, offset) => {
    if (byYear && item.year !== workLastYear) {
      const heading = document.createElement('h3');
      heading.className = 'work-year';
      heading.textContent = item.year || 'Undated';
      grid.appendChild(heading);
      workLastYear = item.year;
    }
    const card = item.kind === 'app' ? buildAppCard(item) : buildMediaCard(item);
    markReveal(card, offset % 6);
    grid.appendChild(card);
  });
  observeReveal(grid);

  workShown += batch.length;
  updateWorkSentinel();
}

// Shows/hides the sentinel that triggers the next batch. Once every item
// in the active view is on screen there's nothing left to watch for.
function updateWorkSentinel() {
  const sentinel = document.getElementById('work-sentinel');
  if (sentinel) sentinel.hidden = workShown >= workView.length;
}

// Infinite scroll: a thin, empty element sits just below the grid.
// As soon as it drifts into view (with a chunky rootMargin so the next
// batch is already rendered before the visitor reaches the bottom),
// the next page is appended — same reveal animation as everything else.
const workScrollObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting && workShown < workView.length) appendWorkBatch();
  });
}, { rootMargin: '600px 0px' });

function initWorkInfiniteScroll() {
  const sentinel = document.getElementById('work-sentinel');
  if (sentinel) workScrollObserver.observe(sentinel);
}

// ---- lightbox (stills + videos only; apps open their own detail panel) ----

function openLightbox(index) {
  if (index < 0) return;
  workLightboxIndex = index;
  const lightbox = document.getElementById('lightbox');
  updateLightbox();
  lightbox.classList.add('open');
  lightbox.setAttribute('aria-hidden', 'false');
}

function closeLightbox() {
  const lightbox = document.getElementById('lightbox');
  lightbox.classList.remove('open');
  lightbox.setAttribute('aria-hidden', 'true');
  const video = document.getElementById('lightbox-video');
  if (video) { video.pause(); video.removeAttribute('src'); video.load(); }
}

function updateLightbox() {
  const item = workMedia[workLightboxIndex];
  if (!item) return;
  const imgEl = document.getElementById('lightbox-img');
  const videoEl = document.getElementById('lightbox-video');

  if (item.media === 'video') {
    imgEl.hidden = true;
    imgEl.removeAttribute('src');
    videoEl.hidden = false;
    videoEl.src = galleryPath(item.file);
    if (item.poster) videoEl.poster = galleryPath(item.poster);
    videoEl.currentTime = 0;
    videoEl.play().catch(() => {});
  } else {
    videoEl.hidden = true;
    videoEl.pause();
    videoEl.removeAttribute('src');
    imgEl.hidden = false;
    imgEl.src = galleryPath(item.file);
    imgEl.alt = item.caption || 'Render';
  }

  document.getElementById('lightbox-caption').textContent = item.caption || '';
}

function stepLightbox(delta) {
  const n = workMedia.length;
  if (!n) return;
  workLightboxIndex = (workLightboxIndex + delta + n) % n;
  updateLightbox();
}

function initLightbox() {
  document.getElementById('lightbox-close').addEventListener('click', closeLightbox);
  document.getElementById('lightbox-prev').addEventListener('click', () => stepLightbox(-1));
  document.getElementById('lightbox-next').addEventListener('click', () => stepLightbox(1));
  document.getElementById('lightbox').addEventListener('click', (e) => {
    if (e.target.id === 'lightbox') closeLightbox();
  });
  document.addEventListener('keydown', (e) => {
    const lightbox = document.getElementById('lightbox');
    if (!lightbox.classList.contains('open')) return;
    if (e.key === 'Escape') closeLightbox();
    if (e.key === 'ArrowLeft') stepLightbox(-1);
    if (e.key === 'ArrowRight') stepLightbox(1);
  });
}

// ---------------------------------------------------------------
// Work history / skills / achievements / education
// All sourced from data/profile.json — a single hand-edited file,
// separate from the projects/ folder system above.
// ---------------------------------------------------------------

function renderExperience(experience) {
  const container = document.getElementById('exp-list');
  container.innerHTML = experience.map((job, jobIndex) => {
    const positionsHtml = job.positions.map((pos, i) => {
      const linksBlock = pos.links && pos.links.length
        ? `<div class="exp-links">
             <p class="exp-links-label">Portfolio highlights</p>
             <div class="exp-links-row">
               ${pos.links.map(l => l.url
                 ? `<a href="${l.url}" target="_blank" rel="noopener">${l.label}</a>`
                 : `<span class="exp-link-plain">${l.label}</span>`
               ).join('')}
             </div>
           </div>`
        : '';
      return `
        <div class="exp-position${i > 0 ? ' exp-position-sub' : ''}">
          <div class="exp-position-dates">${pos.date}</div>
          <div class="exp-content">
            <p class="exp-role">${pos.role}</p>
            <ul class="exp-bullets">
              ${pos.bullets.map(b => `<li>${b}</li>`).join('')}
            </ul>
            ${linksBlock}
          </div>
        </div>
      `;
    }).join('');

    const companyLabel = job.website
      ? `<a class="exp-company-link" href="${job.website}" target="_blank" rel="noopener">${job.company}</a>`
      : job.company;

    return `
      <div class="exp-panel reveal" style="--reveal-delay:${Math.min(jobIndex, 5) * 70}ms">
        <h3 class="exp-company">${companyLabel}</h3>
        <div class="exp-positions">${positionsHtml}</div>
      </div>
    `;
  }).join('');
  observeReveal(container);
}

function renderSkills(skills) {
  const container = document.getElementById('skills-grid');
  const groups = [
    { title: 'Software & technical knowledge', items: skills.software },
    { title: 'Expertise', items: skills.expertise },
    { title: 'Soft skills', items: skills.soft }
  ];
  container.innerHTML = groups.map((g, i) => `
    <div class="skills-group reveal" style="--reveal-delay:${i * 90}ms">
      <h3>${g.title}</h3>
      <ul>${g.items.map(i => `<li>${i}</li>`).join('')}</ul>
    </div>
  `).join('');
  observeReveal(container);
}

function renderAchievements(achievements) {
  const container = document.getElementById('achievements-list');
  container.innerHTML = achievements.map((a, i) => `
    <div class="achievement-row reveal" style="--reveal-delay:${Math.min(i, 5) * 60}ms">
      <span class="achievement-year">${a.year}</span>
      <span class="achievement-title">${a.title}</span>
      <span class="achievement-result">${a.result}</span>
    </div>
  `).join('');
  observeReveal(container);
}

function renderEducationAndLanguages(education, languages) {
  const container = document.getElementById('edu-lang-grid');
  container.innerHTML = `
    <div class="reveal">
      <h3>Education</h3>
      ${education.map(e => `
        <div class="edu-item">
          <div class="school">${e.school}</div>
          <div class="location">${e.location}</div>
        </div>
      `).join('')}
    </div>
    <div class="reveal" style="--reveal-delay:90ms">
      <h3>Languages</h3>
      ${languages.map(l => `
        <div class="lang-item"><span>${l.lang}</span><span class="level">${l.level}</span></div>
      `).join('')}
    </div>
  `;
  observeReveal(container);
}

// ---------------------------------------------------------------
// Footer contact info — built at runtime instead of sitting in the
// HTML as plain mailto:/tel: links, so simple scrapers that just
// pattern-match the page source don't pick up the raw address/number.
// ---------------------------------------------------------------

function initContactLinks() {
  const emailUser = 'strahinja.drazic.cgi';
  const emailDomain = 'gmail.com';
  const email = `${emailUser}@${emailDomain}`;

  const emailEl = document.getElementById('footer-email');
  if (emailEl) {
    const a = document.createElement('a');
    a.href = `mailto:${email}`;
    a.textContent = email;
    emailEl.appendChild(a);
  }

  const phoneDigits = ['+381', '61', '1649636'];
  const phoneDisplay = '+381 61 1649636';
  const phoneHref = phoneDigits.join('');

  const phoneEl = document.getElementById('footer-phone');
  if (phoneEl) {
    const a = document.createElement('a');
    a.href = `tel:${phoneHref}`;
    a.textContent = phoneDisplay;
    phoneEl.appendChild(a);
  }
}

async function loadProfile() {
  const res = await fetch('data/profile.json');
  if (!res.ok) throw new Error('Could not load data/profile.json');
  return res.json();
}

async function init() {
  document.querySelectorAll('.section-head').forEach(el => markReveal(el));
  observeReveal();
  initContactLinks();

  try {
    const [apps, media] = await Promise.all([
      loadAppItems().catch(err => { console.error(err); return []; }),
      loadGalleryItems().catch(err => { console.error(err); return []; })
    ]);
    workItems = [...apps, ...media].sort((a, b) => b.year - a.year); // stable: apps first within a year
    initLightbox();
    initAppDetail();
    initWorkInfiniteScroll();
    if (!workItems.length) throw new Error('nothing found in projects.json or gallery/gallery.json');
    buildWorkFilters();
  } catch (err) {
    document.getElementById('work-grid').innerHTML =
      `<p class="loading">Couldn't load work — if you opened this file directly, run it through a local server instead (see README). (${err.message})</p>`;
    console.error(err);
  }

  try {
    const profile = await loadProfile();
    renderExperience(profile.experience);
    renderSkills(profile.skills);
    renderAchievements(profile.achievements);
    renderEducationAndLanguages(profile.education, profile.languages);
  } catch (err) {
    console.error(err);
  }
}

init();
