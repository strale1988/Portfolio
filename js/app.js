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
// Header parallax: as you scroll through the hero, the text drifts
// upward and fades a bit faster than the page itself scrolls,
// giving it a sense of depth. Driven by a throttled scroll listener
// and only ever writes transform/opacity (compositor-only, no
// layout reads of anything that changes shape) — safe from the
// jitter the old height-driven effect had.
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
    hero.style.opacity = String(1 - progress * 0.85);

    heroReadouts.forEach(el => {
      el.style.opacity = String(1 - progress * 1.3);
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
//
// Nothing here is tied to scroll position, so the grid never
// appears to move as you scroll; only the effects above do.
// Respects prefers-reduced-motion by keeping the (still correctly
// aligned) static grid but skipping all pointer-driven animation.
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

  let cssWidth = 0, cssHeight = 0;
  let cell = DEFAULT_CELL, rowOffset = 0;
  let lineColor = 'rgba(0,0,0,0.05)';
  let lastFrameTime = 0;

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
        y: rowOffset + row * cell + cell / 2,
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

    // Base grid, straight and cheap.
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = 0; x <= cssWidth + 1; x += cell) {
      ctx.moveTo(Math.round(x) + 0.5, 0);
      ctx.lineTo(Math.round(x) + 0.5, cssHeight);
    }
    for (let y = ((rowOffset % cell) + cell) % cell; y <= cssHeight + 1; y += cell) {
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

      const col = Math.floor(p.drawX / cell);
      const row = Math.floor((p.drawY - rowOffset) / cell);
      const spread = speedBoost > 0.5 ? 2 : 1;

      for (let dr = -spread; dr <= spread; dr++) {
        for (let dc = -spread; dc <= spread; dc++) {
          const cx = (col + dc) * cell;
          const cy = rowOffset + (row + dr) * cell;
          const dist = Math.hypot(cx + cell / 2 - p.drawX, cy + cell / 2 - p.drawY);
          const falloff = Math.max(0, 1 - dist / reach);
          if (falloff <= 0) continue;
          const alpha = falloff * p.strength * baseGlowAlpha * strengthMult;
          if (alpha <= 0.003) continue;
          ctx.fillStyle = tealRgba(alpha);
          ctx.fillRect(cx, cy, cell, cell);
        }
      }
    }

    // Ambient flicker: a single cell softly breathing in/out.
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

  resize();
  if (!reduceMotion) {
    flickerTimerId = setTimeout(scheduleFlicker, FLICKER_MIN_GAP + Math.random() * (FLICKER_MAX_GAP - FLICKER_MIN_GAP));
  }
}

initSiteGrid();

// ---------------------------------------------------------------
// Portfolio timeline renderer.
// Reads /projects.json (a list of folder names), then reads
// /projects/<slug>/info.txt for each one. No build step required.
// ---------------------------------------------------------------

async function loadManifest() {
  const res = await fetch('projects.json');
  if (!res.ok) throw new Error('Could not load projects.json');
  return res.json();
}

async function loadProject(slug) {
  const res = await fetch(`projects/${slug}/info.txt`);
  if (!res.ok) throw new Error(`Missing info.txt for ${slug}`);
  const raw = await res.text();
  return parseInfo(raw, slug);
}

// Parses the simple "key: value" info.txt format.
// - Lines starting with # are comments.
// - `link:` may repeat; format is "Label | https://url".
// - `tags:` is a comma separated list.
function parseInfo(raw, slug) {
  const project = { slug, title: slug, category: 'Uncategorized', date: '', description: '', tags: [], links: [] };
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

// Pulls a sortable year out of a date string like "2024" or "2019-2023".
function sortYear(dateStr) {
  const match = dateStr.match(/\d{4}/g);
  return match ? parseInt(match[match.length - 1], 10) : 0;
}

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

function buildCard(project) {
  const card = document.createElement('div');
  card.className = 'project-card';
  card.dataset.category = project.category;

  const tagsRow = project.tags.length
    ? `<div class="tag-list">${project.tags.map(t => `<span class="tag">${t}</span>`).join('')}</div>`
    : '';

  const linksRow = project.links.length
    ? `<div class="links-row">${project.links.map(l => `<a href="${l.url}" target="_blank" rel="noopener">${l.label} ↗</a>`).join('')}</div>`
    : '';

  card.innerHTML = `
    <div class="project-tags-row">
      <span class="meta-chip category">${project.category}</span>
      <span class="meta-chip">${project.date}</span>
    </div>
    <h3>${project.title}</h3>
    <p class="desc">${project.description}</p>
    ${tagsRow}
    ${linksRow}
  `;

  return card;
}

function render(projects, activeCategory) {
  const container = document.getElementById('timeline-items');
  container.innerHTML = '';

  const filtered = activeCategory === 'All'
    ? projects
    : projects.filter(p => p.category === activeCategory);

  if (!filtered.length) {
    container.innerHTML = '<p class="loading">Nothing here yet.</p>';
    return;
  }

  let i = 0;
  for (const project of filtered) {
    const card = buildCard(project);
    markReveal(card, i++ % 6);
    container.appendChild(card);
  }
  observeReveal(container);
}

function buildFilters(projects) {
  const categories = ['All', ...new Set(projects.map(p => p.category))];
  const nav = document.getElementById('filters');
  nav.innerHTML = '';

  let active = 'All';
  categories.forEach(cat => {
    const chip = document.createElement('button');
    chip.className = 'filter-chip' + (cat === 'All' ? ' active' : '');
    chip.textContent = cat;
    chip.addEventListener('click', () => {
      active = cat;
      nav.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      render(projects, active);
    });
    nav.appendChild(chip);
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

// ---------------------------------------------------------------
// Render gallery (standalone images, not tied to a project).
// Reads /gallery/gallery.json — an array of either strings
// ("01.jpg") or objects ({ "file": "01.jpg", "caption": "..." }).
// ---------------------------------------------------------------

// ---------------------------------------------------------------
// Header background stripes (see the CSS comment for how the
// hard-cut effect works). Reads /header/header.json — an array of
// filenames, same manifest shape as gallery.json. Missing manifest
// or empty list just removes the container, no error shown.
// ---------------------------------------------------------------

async function loadHeaderBgManifest() {
  try {
    const res = await fetch('header/header.json');
    if (!res.ok) return [];
    const raw = await res.json();
    return raw.map(entry => (typeof entry === 'string' ? entry : entry.file)).filter(Boolean);
  } catch (err) {
    return [];
  }
}

function renderHeaderBgStripes(files) {
  const container = document.getElementById('header-bg-stripes');
  if (!container) return;
  if (!files.length) {
    container.remove();
    return;
  }
  container.innerHTML = files
    .map(file => `<div class="header-bg-stripe" style="background-image:url('header/${file}')"></div>`)
    .join('');
}

let galleryImages = [];
let galleryIndex = 0;
let galleryShown = 0;
const GALLERY_PAGE_SIZE = 15;

async function loadGalleryManifest() {
  const res = await fetch('gallery/gallery.json');
  if (!res.ok) throw new Error('Could not load gallery/gallery.json');
  const raw = await res.json();
  return raw.map(entry => typeof entry === 'string'
    ? { file: entry, caption: '' }
    : { file: entry.file, caption: entry.caption || '' });
}

function renderGallery(images) {
  const container = document.getElementById('gallery-grid');
  container.innerHTML = '';
  galleryShown = 0;

  if (!images.length) {
    container.innerHTML = '<p class="loading">No renders yet — drop images into the gallery/ folder and list them in gallery/gallery.json.</p>';
    updateGalleryLoadMoreVisibility();
    return;
  }

  appendGalleryBatch();
}

// Appends the next page of gallery items (GALLERY_PAGE_SIZE at a time)
// to the grid without touching what's already rendered, then shows or
// hides the "Load more" button depending on whether any images remain.
function appendGalleryBatch() {
  const container = document.getElementById('gallery-grid');
  const nextImages = galleryImages.slice(galleryShown, galleryShown + GALLERY_PAGE_SIZE);

  nextImages.forEach((image, offset) => {
    const i = galleryShown + offset;
    const item = document.createElement('div');
    item.className = 'gallery-item';
    item.innerHTML = `<img src="gallery/${image.file}" alt="${image.caption || 'Render'}" loading="lazy">`;
    item.addEventListener('click', () => openLightbox(i));
    makeActivatable(item, image.caption ? `Open render: ${image.caption}` : 'Open render');
    item.querySelector('img').onerror = function () { item.remove(); };
    markReveal(item, offset % 6);
    container.appendChild(item);
  });
  observeReveal(container);

  galleryShown += nextImages.length;
  updateGalleryLoadMoreVisibility();
}

function updateGalleryLoadMoreVisibility() {
  const btn = document.getElementById('gallery-load-more');
  if (!btn) return;
  btn.hidden = galleryShown >= galleryImages.length;
}

function initGalleryLoadMore() {
  const btn = document.getElementById('gallery-load-more');
  if (!btn) return;
  btn.addEventListener('click', () => appendGalleryBatch());
}

function openLightbox(index) {
  galleryIndex = index;
  const lightbox = document.getElementById('lightbox');
  updateLightbox();
  lightbox.classList.add('open');
  lightbox.setAttribute('aria-hidden', 'false');
}

function closeLightbox() {
  const lightbox = document.getElementById('lightbox');
  lightbox.classList.remove('open');
  lightbox.setAttribute('aria-hidden', 'true');
}

function updateLightbox() {
  const image = galleryImages[galleryIndex];
  document.getElementById('lightbox-img').src = `gallery/${image.file}`;
  document.getElementById('lightbox-img').alt = image.caption || 'Render';
  document.getElementById('lightbox-caption').textContent = image.caption || '';
}

function stepLightbox(delta) {
  galleryIndex = (galleryIndex + delta + galleryImages.length) % galleryImages.length;
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
    const headerImages = await loadHeaderBgManifest();
    renderHeaderBgStripes(headerImages);
  } catch (err) {
    console.error(err);
  }

  try {
    const slugs = await loadManifest();
    const projects = (await Promise.all(slugs.map(loadProject)))
      .sort((a, b) => sortYear(b.date) - sortYear(a.date));
    buildFilters(projects);
    render(projects, 'All');
  } catch (err) {
    document.getElementById('timeline-items').innerHTML =
      `<p class="loading">Couldn't load projects — if you opened this file directly, run it through a local server instead (see README). (${err.message})</p>`;
    console.error(err);
  }

  try {
    galleryImages = await loadGalleryManifest();
    renderGallery(galleryImages);
    initLightbox();
    initGalleryLoadMore();
  } catch (err) {
    document.getElementById('gallery-grid').innerHTML =
      `<p class="loading">Couldn't load the gallery. (${err.message})</p>`;
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
