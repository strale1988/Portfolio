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
  const grid = document.querySelector('.hud-grid');
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

    // The grid behind the text moves faster than the page (>1x), so it
    // recedes past the text and reads as a background plane instead of
    // sitting flush with it. It's oversized in CSS so this never
    // uncovers an edge.
    if (grid) {
      grid.style.transform = `translateY(${scrolled * -0.5}px)`;
    }

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

initHeaderParallax();

// ---------------------------------------------------------------
// Portfolio timeline renderer.
// Reads /projects.json (a list of folder names), then reads
// /projects/<slug>/info.txt for each one. No build step required.
// ---------------------------------------------------------------

const MAX_GALLERY_PROBE = 10; // tries images/1.jpg .. images/10.jpg

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
  const project = { slug, title: slug, category: 'Uncategorized', date: '', description: '', tags: [], links: [], cover: 'images/cover.jpg' };
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
function firstYearLabel(dateStr) {
  const match = dateStr.match(/\d{4}/);
  return match ? match[0] : dateStr;
}

function buildFrame(project) {
  const frame = document.createElement('div');
  frame.className = 'frame';
  frame.innerHTML = `
    <img src="projects/${project.slug}/${project.cover}" alt="${project.title} cover" loading="lazy"
         onerror="this.closest('.frame').style.background='var(--panel-raised)'; this.remove();">
  `;
  frame.addEventListener('click', () => toggleGallery(project, frame.closest('.project-card')));
  return frame;
}

function toggleGallery(project, cardEl) {
  let gallery = cardEl.querySelector('.gallery');
  if (gallery) {
    gallery.classList.toggle('open');
    return;
  }
  gallery = document.createElement('div');
  gallery.className = 'gallery open';
  cardEl.appendChild(gallery);

  for (let i = 1; i <= MAX_GALLERY_PROBE; i++) {
    const img = document.createElement('img');
    img.loading = 'lazy';
    img.alt = `${project.title} detail ${i}`;
    img.onerror = () => img.remove();
    img.src = `projects/${project.slug}/images/${i}.jpg`;
    gallery.appendChild(img);
  }
}

function buildCard(project) {
  const card = document.createElement('div');
  card.className = 'project-card';
  card.dataset.category = project.category;

  const body = document.createElement('div');
  body.className = 'project-body';

  const tagsRow = project.tags.length
    ? `<div class="tag-list">${project.tags.map(t => `<span class="tag">${t}</span>`).join('')}</div>`
    : '';

  const linksRow = project.links.length
    ? `<div class="links-row">${project.links.map(l => `<a href="${l.url}" target="_blank" rel="noopener">${l.label}</a>`).join('')}</div>`
    : '';

  body.innerHTML = `
    <div class="project-tags-row">
      <span class="meta-chip category">${project.category}</span>
      <span class="meta-chip">${project.date}</span>
    </div>
    <h3>${project.title}</h3>
    <p class="desc">${project.description}</p>
    ${tagsRow}
    ${linksRow}
  `;

  card.appendChild(buildFrame(project));
  card.appendChild(body);
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

  let lastYear = null;
  let i = 0;
  for (const project of filtered) {
    const year = firstYearLabel(project.date);
    if (year !== lastYear) {
      const marker = document.createElement('div');
      marker.className = 'year-marker';
      markReveal(marker);
      container.appendChild(marker);
      lastYear = year;
    }
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
               ${pos.links.map(l => `<a href="${l.url}" target="_blank" rel="noopener">${l.label}</a>`).join('')}
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

    return `
      <div class="exp-panel reveal" style="--reveal-delay:${Math.min(jobIndex, 5) * 70}ms">
        <h3 class="exp-company">${job.company}</h3>
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

let galleryImages = [];
let galleryIndex = 0;

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

  if (!images.length) {
    container.innerHTML = '<p class="loading">No renders yet — drop images into the gallery/ folder and list them in gallery/gallery.json.</p>';
    return;
  }

  images.forEach((image, i) => {
    const item = document.createElement('div');
    item.className = 'gallery-item';
    item.innerHTML = `<img src="gallery/${image.file}" alt="${image.caption || 'Render'}" loading="lazy">`;
    item.addEventListener('click', () => openLightbox(i));
    item.querySelector('img').onerror = function () { item.remove(); };
    markReveal(item, i % 6);
    container.appendChild(item);
  });
  observeReveal(container);
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
