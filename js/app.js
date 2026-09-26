function jumpToTop() {
  try { window.scrollTo({ top: 0, left: 0, behavior: 'instant' }); }
  catch (e) { window.scrollTo(0, 0); }
}
if ('scrollRestoration' in history) {
  history.scrollRestoration = 'manual';
}
jumpToTop();

let visitorHasScrolled = false;
['wheel', 'touchstart', 'keydown', 'mousedown'].forEach(type => {
  window.addEventListener(type, () => { visitorHasScrolled = true; }, { once: true, passive: true });
});
window.addEventListener('load', () => { if (!visitorHasScrolled) jumpToTop(); });

document.addEventListener('contextmenu', (e) => e.preventDefault());
document.addEventListener('dragstart', (e) => e.preventDefault());

const SMOOTH_SCROLL = {
  lerp: 0.09,
  wheelMultiplier: 1,
  anchorDuration: 1.2,
  topDuration: 1.4
};
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
let lenis = null;
const scrollListeners = [];

function onScroll(fn) { scrollListeners.push(fn); }
function currentScroll() { return lenis ? lenis.scroll : window.scrollY; }
function emitScroll() {
  const y = currentScroll();
  for (const fn of scrollListeners) fn(y);
}

const easeInOutCubic = t => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);

function lockPageScroll(locked) {
  if (lenis) {
    if (locked) lenis.stop(); else lenis.start();
  } else {
    document.documentElement.classList.toggle('scroll-locked', locked);
  }
}

function initSmoothScroll() {
  if (!prefersReducedMotion && typeof window.Lenis === 'function') {
    try {
      lenis = new window.Lenis({
        autoRaf: true,
        lerp: SMOOTH_SCROLL.lerp,
        wheelMultiplier: SMOOTH_SCROLL.wheelMultiplier,
        smoothWheel: true,
        allowNestedScroll: true
      });
    } catch (err) {
      console.warn('Smooth scroll unavailable, falling back to native scrolling.', err);
      lenis = null;
    }
  }

  if (lenis) lenis.on('scroll', emitScroll);
  else window.addEventListener('scroll', emitScroll, { passive: true });
}

initSmoothScroll();

function updateNavHeightVar() {
  const nav = document.querySelector('.site-nav');
  if (nav) document.documentElement.style.setProperty('--nav-h', `${nav.offsetHeight}px`);
}
updateNavHeightVar();
window.addEventListener('resize', updateNavHeightVar);
if (document.fonts && document.fonts.ready) {
  document.fonts.ready.then(updateNavHeightVar).catch(() => {});
}

function initThemeToggle() {
  const btn = document.getElementById('theme-toggle');
  if (!btn) return;

  btn.addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
    const next = current === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch (e) {  }
    document.dispatchEvent(new CustomEvent('themechange', { detail: { theme: next } }));
  });
}

initThemeToggle();

document.addEventListener('themechange', () => {
  document.querySelectorAll('img[data-nda-img]').forEach(img => {
    img.src = galleryPath('NDA');
  });
  const lightbox = document.getElementById('lightbox');
  if (lightbox && lightbox.classList.contains('open')) {
    const item = workMedia[workLightboxIndex];
    if (item && item.file.includes('NDA')) updateLightbox();
  }
});

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

const HEADER_SCROLL = {
  TEXT_FADE_END: 0.45
};

function initHeaderParallax() {
  if (prefersReducedMotion) return;

  const hero = document.querySelector('.hero-content');
  const hud = document.querySelector('.hud');
  if (!hero || !hud) return;

  const heroReadouts = document.querySelectorAll('.hud-readout');
  let range = hud.offsetHeight || 1;
  let parked = false;

  function update(y) {
    const scrolled = Math.min(Math.max(y, 0), range);
    const progress = scrolled / range;

    if (progress >= HEADER_SCROLL.TEXT_FADE_END) {
      if (parked) return;
      parked = true;
    } else {
      parked = false;
    }

    hero.style.transform = `translate3d(0, ${scrolled * 0.35}px, 0)`;

    const textOpacity = 1 - Math.min(progress / HEADER_SCROLL.TEXT_FADE_END, 1);
    hero.style.opacity = String(textOpacity);
    heroReadouts.forEach(el => {
      el.style.opacity = String(textOpacity);
    });
  }

  window.addEventListener('resize', () => {
    range = hud.offsetHeight || 1;
    parked = false;
    update(currentScroll());
  });

  onScroll(update);
  update(currentScroll());
}

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

      setTimeout(() => el.remove(), 700);
    }, wait);
  }

  if (document.readyState === 'complete') {
    hide();
  } else {
    window.addEventListener('load', hide, { once: true });
  }

  setTimeout(hide, 4000);
}

initSitePreloader();

initHeaderParallax();

// As the hero scrolls by, an overlay canvas dissolves it into squares —
// bottom rows first, with a little per-cell jitter so the wipe line reads
// as organic rather than a straight edge — matching the site's grid motif
// and giving the hero a more deliberate exit than a plain scroll-away.
function initHeroDissolve() {
  if (prefersReducedMotion) return;

  const canvas = document.querySelector('.hero-dissolve');
  const hud = document.querySelector('.hud');
  if (!canvas || !hud || !canvas.getContext) return;

  const ctx = canvas.getContext('2d');
  const CELL = 44;
  const START = 0.2;   // reveal progress (0-1 of hero height) where dissolve begins
  const END = 0.92;    // progress where the hero is fully gone
  const BAND = 0.16;   // how quickly each cell fades in, in progress units
  const JITTER = 0.22; // per-cell randomness added to its row threshold

  let cssWidth = 0, cssHeight = 0, cols = 0, rows = 0;
  let jitters = [];
  let bgColor = '#f5f4ef';
  let range = hud.offsetHeight || 1;
  let lastR = -1;
  let fullyDrawn = false;

  function seededRandom(seed) {
    const x = Math.sin(seed * 12.9898) * 43758.5453;
    return x - Math.floor(x);
  }

  function readColor() {
    bgColor = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || bgColor;
  }

  function buildGrid() {
    const w = hud.clientWidth || window.innerWidth;
    const h = hud.clientHeight || window.innerHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    cssWidth = w;
    cssHeight = h;
    canvas.width = Math.round(w * dpr);
    canvas.height = Math.round(h * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    cols = Math.max(1, Math.ceil(w / CELL));
    rows = Math.max(1, Math.ceil(h / CELL));
    jitters = [];
    for (let r = 0; r < rows; r++) {
      const row = [];
      for (let c = 0; c < cols; c++) row.push((seededRandom(r * 97 + c * 31 + 1) - 0.5) * JITTER);
      jitters.push(row);
    }
    range = hud.offsetHeight || 1;
    lastR = -1;
    render(currentScroll());
  }

  function render(y) {
    const progress = Math.min(Math.max(y, 0), range) / range;
    const r = Math.min(Math.max((progress - START) / (END - START), 0), 1);
    if (r === lastR) return;
    lastR = r;

    if (r <= 0) {
      ctx.clearRect(0, 0, cssWidth, cssHeight);
      fullyDrawn = false;
      return;
    }
    if (r >= 1 && fullyDrawn) return;

    ctx.clearRect(0, 0, cssWidth, cssHeight);
    ctx.fillStyle = bgColor;

    for (let row = 0; row < rows; row++) {
      const rowThreshold = rows > 1 ? 1 - (row / (rows - 1)) : 1;
      for (let col = 0; col < cols; col++) {
        const threshold = Math.min(Math.max(rowThreshold + jitters[row][col], 0), 1);
        const alpha = Math.min(Math.max((r - threshold) / BAND, 0), 1);
        if (alpha <= 0) continue;
        ctx.globalAlpha = alpha;
        ctx.fillRect(col * CELL, row * CELL, CELL + 1, CELL + 1);
      }
    }
    ctx.globalAlpha = 1;
    fullyDrawn = r >= 1;
  }

  readColor();
  buildGrid();

  onScroll(render);
  window.addEventListener('resize', buildGrid);
  document.addEventListener('themechange', () => {
    readColor();
    lastR = -1;
    render(currentScroll());
  });
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(buildGrid).catch(() => {});
  }
}

initHeroDissolve();

let autoScrolling = false;

function smoothScrollTo(target, duration) {
  if (lenis) {
    lenis.scrollTo(target, {
      duration,
      easing: easeInOutCubic,
      onStart: () => { autoScrolling = true; },
      onComplete: () => { autoScrolling = false; }
    });
  } else {
    autoScrolling = true;
    window.scrollTo({ top: target, behavior: prefersReducedMotion ? 'auto' : 'smooth' });
    setTimeout(() => { autoScrolling = false; }, duration * 1000 + 80);
  }
}

function initBackToTop() {
  const btn = document.getElementById('back-to-top');
  if (!btn) return;

  let visible = false;
  function update(y) {
    const show = y > window.innerHeight;
    if (show === visible) return;
    visible = show;
    btn.classList.toggle('visible', show);
  }
  onScroll(update);

  btn.addEventListener('click', () => smoothScrollTo(0, SMOOTH_SCROLL.topDuration));

  update(currentScroll());
}

initBackToTop();

function initTabs() {
  const buttons = Array.from(document.querySelectorAll('.tab-btn'));
  const sections = buttons
    .map(btn => document.getElementById(btn.dataset.panel))
    .filter(Boolean);
  if (!buttons.length || !sections.length) return;

  function setActive(panel) {
    buttons.forEach(btn => btn.classList.toggle('active', btn.dataset.panel === panel));
  }

  function navHeight() {
    const nav = document.querySelector('.site-nav');
    return nav ? nav.offsetHeight : 0;
  }

  buttons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      const target = document.getElementById(btn.dataset.panel);
      if (!target) return;
      e.preventDefault();

      const fromTop = target.getBoundingClientRect().top + currentScroll();
      const goingDown = fromTop > currentScroll();
      if (window.__gridSweep) window.__gridSweep(goingDown ? 1 : -1);

      smoothScrollTo(fromTop - navHeight(), SMOOTH_SCROLL.anchorDuration);
      setActive(btn.dataset.panel);
    });
  });

  // Scrollspy: highlight whichever section currently owns the band just
  // below the sticky nav, so the active tab tracks natural scrolling too.
  const spyObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) setActive(entry.target.id);
    });
  }, { rootMargin: `-${Math.max(navHeight(), 1)}px 0px -70% 0px`, threshold: 0 });

  sections.forEach(sec => spyObserver.observe(sec));
}

initTabs();

function initSiteGrid() {
  const canvas = document.querySelector('.site-grid');
  if (!canvas || !canvas.getContext) return;

  const ctx = canvas.getContext('2d');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const DEFAULT_CELL = 40;
  const MIN_CELL = 30;
  const MAX_CELL = 56;
  const TEXT_CLEARANCE = 6;
  const FLICKER_DURATION = 900;
  const FLICKER_MIN_GAP = 500;
  const FLICKER_MAX_GAP = 1600;
  const SCROLL_PARALLAX = 0.25;

  let cssWidth = 0, cssHeight = 0;
  let cell = DEFAULT_CELL, rowOffset = 0;
  let lineColor = 'rgba(0,0,0,0.05)';
  let tealHex = '#0c7c6c';
  let isDark = false;
  let lastFrameTime = 0;
  let scrollOffset = reduceMotion ? 0 : window.scrollY * SCROLL_PARALLAX;

  function readColor() {
    const styles = getComputedStyle(document.documentElement);
    lineColor = styles.getPropertyValue('--grid-line').trim() || lineColor;
    tealHex = styles.getPropertyValue('--teal').trim() || tealHex;
    isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  }

  function hasClash(candidateCell, offset, bands) {
    for (let y = offset; y < cssHeight; y += candidateCell) {
      for (const [top, bottom] of bands) {
        if (y >= top && y <= bottom) return true;
      }
    }
    return false;
  }

  function solveRowLayout() {
    const heroEls = document.querySelectorAll('.hero-content > *');
    if (!heroEls.length) return { cell: DEFAULT_CELL, offset: 0 };

    const bands = Array.from(heroEls).map(el => {
      let top = 0;
      for (let n = el; n; n = n.offsetParent) top += n.offsetTop;
      return [top - TEXT_CLEARANCE, top + el.offsetHeight + TEXT_CLEARANCE];
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

  function resize(force) {
    const w = canvas.clientWidth || window.innerWidth;
    const h = canvas.clientHeight || window.innerHeight;

    if (!force && w === cssWidth && h === cssHeight) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    cssWidth = w;
    cssHeight = h;
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
      const instSpeed = dt > 0 ? dist / dt : 0;
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

    const tealRgba = (a) => hexToRgba(tealHex, a);
    const baseGlowAlpha = isDark ? 0.22 : 0.14;

    ctx.save();
    ctx.translate(0, -scrollOffset);

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

      const speedBoost = Math.min(p.speed / 1.2, 1);
      const reach = cell * (1.6 + speedBoost * 0.9);
      const strengthMult = 1 + speedBoost * 0.6;

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
  window.addEventListener('resize', () => resize(false));
  document.fonts?.ready?.then(() => resize(true));

  new MutationObserver(() => {
    readColor();
    if (!rafId) draw(performance.now());
  }).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });

  if (!reduceMotion) {
    onScroll((y) => {
      scrollOffset = y * SCROLL_PARALLAX;

      if (!rafId) draw(performance.now());
    });
  }

  function triggerSweep(direction) {
    if (reduceMotion || document.visibilityState !== 'visible') return;
    const cols = Math.max(1, Math.floor(cssWidth / cell));
    const rows = Math.max(1, Math.floor((cssHeight - rowOffset) / cell));
    const order = [...Array(cols).keys()];
    if (direction < 0) order.reverse();
    const stepDelay = 18;
    order.forEach((col, i) => {
      setTimeout(() => {
        const hits = 1 + Math.floor(Math.random() * 2);
        for (let h = 0; h < hits; h++) {
          const row = Math.floor(Math.random() * rows);
          flickers.push({
            x: col * cell + cell / 2,
            y: rowOffset + row * cell + cell / 2 + scrollOffset,
            start: performance.now()
          });
        }
        ensureLoop();
      }, i * stepDelay);
    });
  }
  window.__gridSweep = triggerSweep;

  resize(true);
  if (!reduceMotion) {
    flickerTimerId = setTimeout(scheduleFlicker, FLICKER_MIN_GAP + Math.random() * (FLICKER_MAX_GAP - FLICKER_MIN_GAP));
  }
}

initSiteGrid();

const WORK_PAGE_SIZE = 18;
const WORK_INITIAL_SIZE = 16;
const WORK_LOAD_MORE_SIZE = 10;
const WORK_COLUMNS = 2;

const WORK_MIN_RATIO = 0.75;
const WORK_MAX_RATIO = 2.2;
const WORK_VIDEO_EXTENSIONS = ['mp4', 'webm', 'mov', 'm4v'];

function galleryPath(filename) {
  if (filename.includes('NDA')) {
    const theme = document.documentElement.getAttribute('data-theme') === 'light' ? 'light' : 'dark';
    return `gallery/NDA-${theme}.webp`;
  }
  return `gallery/${filename}`;
}

const WORK_FILTERS = [

  { id: 'visualization', label: 'Visualization', sub: 'Architectural stills and renders.',                  test: it => it.category === 'visualization' && !(it.file || '').includes('NDA') },
  { id: 'animation',     label: 'Animation',     sub: 'Animations and turntables.',                         test: it => it.category === 'animation' },
  { id: 'app',           label: 'Apps & Tools',  sub: 'Interactive apps, web tools and experiences.',       test: it => it.category === 'app' },
  { id: 'tour',          label: 'Virtual Tours', sub: 'Immersive 360° walkthroughs.',                       test: it => it.category === 'tour' },
  { id: 'archive',       label: 'Archive',       sub: 'Everything, newest first.',                          test: () => true, byYear: true }
];

let workItems = [];
let workView = [];
let workMedia = [];
let workShown = 0;
let workFilter = 'archive';
let workLastYear = null;
let workOpenRow = null;
let workLightboxIndex = 0;

const workVideoObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) entry.target.play().catch(() => {});
    else entry.target.pause();
  });
}, { threshold: 0.4 });

function fileExt(file) {
  const match = /\.([a-z0-9]+)$/i.exec(file || '');
  return match ? match[1].toLowerCase() : '';
}

function yearFromFilename(file) {
  const match = /^(\d{4})/.exec(file || '');
  return match ? parseInt(match[1], 10) : 0;
}

function sortName(item) {
  if (item.kind === 'app') return item.title || item.slug || '';
  return (item.file || '').replace(/^\d{4}_?/, '').replace(/\.[a-z0-9]+$/i, '');
}

const workNameCollator = new Intl.Collator('en', { numeric: true, sensitivity: 'base' });
function compareWorkItems(a, b) {
  return (b.year - a.year) || workNameCollator.compare(sortName(a), sortName(b));
}

function sortYear(dateStr) {
  const match = (dateStr || '').match(/\d{4}/g);
  return match ? parseInt(match[match.length - 1], 10) : 0;
}

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

    const category = e.category
      ? e.category
      : (e.type === 'archive' ? 'archive' : (media === 'video' ? 'animation' : 'visualization'));
    return {
      kind: 'media',
      media,
      category,
      file: e.file,
      caption: e.caption || '',
      poster: e.poster || '',
      width: e.width || 0,
      height: e.height || 0,
      featured: e.featured || false,
      year: e.year || yearFromFilename(e.file)
    };
  });
}

async function loadAppItems() {
  const res = await fetch('projects.json');
  if (!res.ok) throw new Error('Could not load projects.json');
  const projects = await res.json();
  return projects
    .filter(p => p && p.slug)
    .map(p => ({
      kind: 'app',
      category: p.type === 'tour' ? 'tour' : 'app',
      slug: p.slug,
      title: p.title || p.slug,
      label: p.category || '',
      date: p.date || '',
      year: sortYear(p.date),
      description: p.description || '',
      tags: p.tags || [],
      links: p.links || [],
      embed: p.embed || '',
      cover: p.cover || '',
      featured: p.featured || false
    }));
}

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

function setCardRatio(card, w, h) {
  if (!w || !h) return;
  const ratio = Math.min(WORK_MAX_RATIO, Math.max(WORK_MIN_RATIO, w / h));
  card.style.setProperty('--ar', ratio.toFixed(4));
}

function buildMediaCard(item) {
  const card = document.createElement('div');
  card.className = 'gallery-item' + (item.media === 'video' ? ' is-video' : '');

  if (item.media === 'video') {
    const posterAttr = item.poster ? ` poster="${galleryPath(item.poster)}"` : '';
    card.innerHTML = `<video src="${galleryPath(item.file)}"${posterAttr} muted loop playsinline preload="metadata" aria-label="${item.caption || 'Animation'}"></video>`;
    const video = card.querySelector('video');
    video.onerror = function () { card.remove(); };

    video.addEventListener('loadedmetadata', () => {
      if (!item.poster) video.currentTime = Math.min(0.1, (video.duration || 1) / 2);
    }, { once: true });
    setCardRatio(card, item.width, item.height);
    video.addEventListener('loadedmetadata', () => setCardRatio(card, video.videoWidth, video.videoHeight));
    workVideoObserver.observe(video);
  } else {
    const ndaAttr = item.file.includes('NDA') ? ' data-nda-img="true"' : '';
    card.innerHTML = `<img src="${galleryPath(item.file)}" alt="${item.caption || 'Render'}" loading="lazy" decoding="async"${ndaAttr}>`;
    const img = card.querySelector('img');
    img.onerror = function () { card.remove(); };
    setCardRatio(card, item.width, item.height);

    img.addEventListener('load', () => setCardRatio(card, img.naturalWidth, img.naturalHeight));
  }

  card.addEventListener('click', () => openLightbox(workMedia.indexOf(item)));
  makeActivatable(card, item.caption ? `Open ${item.caption}` : (item.media === 'video' ? 'Open animation' : 'Open render'));
  return card;
}

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
    card.innerHTML = `<img src="${item.cover}" alt="${item.title}" loading="lazy" decoding="async">
      <div class="app-caption"><p class="app-meta">${appMeta(item)}</p><h3>${item.title}</h3></div>`;

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

let appDetailReturnFocus = null;

function openAppDetail(item) {
  const overlay = document.getElementById('app-detail');
  const cover = document.getElementById('app-detail-cover');

  const isTour = item.category === 'tour' && item.embed;

  if (item.cover && !isTour) {
    cover.hidden = false;
    cover.alt = item.title;
    cover.onerror = function () { cover.hidden = true; };
    cover.src = item.cover;
  } else {
    cover.hidden = true;
    cover.removeAttribute('src');
  }

  const allLinks = (item.embed && !isTour)
    ? [{ label: 'Open in new tab', url: item.embed }, ...item.links]
    : item.links;
  const links = allLinks.length
    ? `<div class="links-row">${allLinks.map(l => `<a href="${l.url}" target="_blank" rel="noopener">${l.label} ↗</a>`).join('')}</div>`
    : '';
  const embed = item.embed
    ? (isTour

        ? `<div class="app-embed-wrap"><iframe class="app-embed-frame" src="${item.embed}" loading="lazy" allow="fullscreen; xr-spatial-tracking; accelerometer; gyroscope" allowfullscreen title="${item.title} — virtual tour"></iframe></div>`
        : `<div class="app-embed-wrap">
            <button type="button" class="app-embed-launch">▶ Launch on this page</button>
          </div>`)
    : '';
  document.getElementById('app-detail-body').innerHTML = `
    <p class="app-meta">${appMeta(item)}</p>
    <h3 id="app-detail-title">${item.title}</h3>
    ${item.description ? `<p class="app-detail-desc">${item.description}</p>` : ''}
    ${appTags(item)}
    ${embed}
    ${links}`;

  if (item.embed && !isTour) {
    const launchBtn = document.querySelector('.app-embed-launch');
    launchBtn.addEventListener('click', () => {
      const wrap = launchBtn.closest('.app-embed-wrap');
      wrap.innerHTML = `<iframe class="app-embed-frame" src="${item.embed}" loading="lazy" allow="fullscreen; xr-spatial-tracking; accelerometer; gyroscope" allowfullscreen title="${item.title} — virtual tour"></iframe>`;
    });
  }

  appDetailReturnFocus = document.activeElement;
  overlay.classList.add('open');
  overlay.setAttribute('aria-hidden', 'false');
  lockPageScroll(true);
  document.getElementById('app-detail-close').focus();
}

function closeAppDetail() {
  const overlay = document.getElementById('app-detail');
  overlay.classList.remove('open');
  overlay.setAttribute('aria-hidden', 'true');
  lockPageScroll(false);

  const embedWrap = overlay.querySelector('.app-embed-wrap');
  if (embedWrap) embedWrap.innerHTML = '';
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

function buildWorkFilters() {
  const nav = document.getElementById('filters');
  nav.innerHTML = '';

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
  workOpenRow = null;

  if (!workView.length) {
    grid.innerHTML = '<p class="loading">Nothing here yet.</p>';
    updateWorkPaging();
    return;
  }

  const byYear = WORK_FILTERS.find(f => f.id === workFilter).byYear;
  appendWorkBatch(byYear ? WORK_PAGE_SIZE : WORK_INITIAL_SIZE);
}

function appendWorkBatch(size) {
  const grid = document.getElementById('work-grid');
  const byYear = WORK_FILTERS.find(f => f.id === workFilter).byYear;
  const batch = workView.slice(workShown, workShown + size);

  batch.forEach((item, offset) => {
    if (byYear && item.year !== workLastYear) {
      const heading = document.createElement('h3');
      heading.className = 'work-year';
      heading.textContent = item.year || 'Undated';
      grid.appendChild(heading);
      workLastYear = item.year;
      workOpenRow = null;
    }
    const card = item.kind === 'app' ? buildAppCard(item) : buildMediaCard(item);
    markReveal(card, offset % 6);

    if (!workOpenRow || workOpenRow.children.length >= WORK_COLUMNS) {
      workOpenRow = document.createElement('div');
      workOpenRow.className = 'gallery-row';
      grid.appendChild(workOpenRow);
    }
    workOpenRow.appendChild(card);
  });
  observeReveal(grid);

  workShown += batch.length;
  updateWorkPaging();
}

function updateWorkPaging() {
  const byYear = WORK_FILTERS.find(f => f.id === workFilter).byYear;
  const remaining = workShown < workView.length;
  const sentinel = document.getElementById('work-sentinel');
  const loadMoreBtn = document.getElementById('work-load-more');
  if (sentinel) sentinel.hidden = !(byYear && remaining);
  if (loadMoreBtn) loadMoreBtn.hidden = !(!byYear && remaining);
}

const workScrollObserver = new IntersectionObserver((entries) => {
  const byYear = WORK_FILTERS.find(f => f.id === workFilter).byYear;
  entries.forEach(entry => {
    if (entry.isIntersecting && byYear && workShown < workView.length) appendWorkBatch(WORK_PAGE_SIZE);
  });
}, { root: null, rootMargin: '600px 0px' });

function initWorkInfiniteScroll() {
  const sentinel = document.getElementById('work-sentinel');
  if (sentinel) workScrollObserver.observe(sentinel);

  const loadMoreBtn = document.getElementById('work-load-more');
  if (loadMoreBtn) {
    loadMoreBtn.addEventListener('click', () => appendWorkBatch(WORK_LOAD_MORE_SIZE));
  }
}

function openLightbox(index) {
  if (index < 0) return;
  workLightboxIndex = index;
  const lightbox = document.getElementById('lightbox');
  updateLightbox();
  lightbox.classList.add('open');
  lightbox.setAttribute('aria-hidden', 'false');
  lockPageScroll(true);
}

function closeLightbox() {
  const lightbox = document.getElementById('lightbox');
  lightbox.classList.remove('open');
  lightbox.setAttribute('aria-hidden', 'true');
  lockPageScroll(false);
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

let toastEl = null;
let toastTimer = null;

function showToast(message) {
  if (!toastEl) {
    toastEl = document.createElement('div');
    toastEl.className = 'toast';
    toastEl.setAttribute('role', 'status');
    toastEl.setAttribute('aria-live', 'polite');
    document.body.appendChild(toastEl);
  }
  toastEl.textContent = message;

  toastEl.classList.remove('visible');
  void toastEl.offsetWidth;
  toastEl.classList.add('visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toastEl.classList.remove('visible'), 2000);
}

async function copyText(text) {
  try {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch (e) {  }

  const previouslyFocused = document.activeElement;
  const ta = document.createElement('textarea');
  ta.value = text;
  ta.setAttribute('readonly', '');

  ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;pointer-events:none;-webkit-user-select:text;user-select:text;';
  document.body.appendChild(ta);
  let ok = false;
  try {
    ta.select();
    ta.setSelectionRange(0, text.length);
    ok = document.execCommand('copy');
  } catch (e) { ok = false; }
  ta.remove();
  if (previouslyFocused && previouslyFocused.focus) previouslyFocused.focus({ preventScroll: true });
  return ok;
}

function copyOnRightClick(link, value, label, hint) {
  link.title = `${hint} · right-click to copy`;
  link.addEventListener('contextmenu', async (e) => {
    e.preventDefault();
    const ok = await copyText(value);
    showToast(ok ? `${label} copied` : `Couldn't copy — ${value}`);
  });
}

function initContactLinks() {
  const emailUser = 'strahinja.drazic.cgi';
  const emailDomain = 'gmail.com';
  const email = `${emailUser}@${emailDomain}`;

  const phoneDigits = ['+381', '61', '1649636'];
  const phoneDisplay = '+381 61 1649636';
  const phoneHref = phoneDigits.join('');

  const ctaEmailEl = document.getElementById('cta-email');
  if (ctaEmailEl) {
    const a = document.createElement('a');
    a.href = `mailto:${email}`;
    a.textContent = email;
    copyOnRightClick(a, email, 'Email', 'Click to email');
    ctaEmailEl.appendChild(a);
  }
  const ctaPhoneEl = document.getElementById('cta-phone');
  if (ctaPhoneEl) {
    const a = document.createElement('a');
    a.href = `tel:${phoneHref}`;
    a.textContent = phoneDisplay;
    copyOnRightClick(a, phoneDisplay, 'Phone number', 'Click to call');
    ctaPhoneEl.appendChild(a);
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
    workItems = [...apps, ...media].sort(compareWorkItems);
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
