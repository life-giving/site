/* ГО «Життєдайна»: стрічка новин (news.html) з news/news.json.
   Запис: { "id": "slug", "date": "2026-10-20", "title": …, "body": "Markdown…", "images": { "<підпис>": "шлях" } }
   title/body — { "uk": "…", "en": "…" } або рядок (= лише українською). Новина без заголовка поточною мовою не показується.
   id — адреса окремої новини news.html?id=…; якщо не задано — береться date.
   Markdown → HTML через marked; зображення в тексті не підтримуються (лише слайдер), сирий HTML екранується. */
(function () {
  var page = document.getElementById('news-page');
  if (!page) return;
  var items = [], loaded = false;

  function esc(s) {
    return String(s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function lang() { return document.documentElement.lang || 'uk'; }
  function dict() { return (window.I18N || {})[lang()] || {}; }
  /* текст поточною мовою; рядок вважається українським */
  function t(v) {
    if (v == null) return '';
    if (typeof v === 'string') return lang() === 'uk' ? v : '';
    return v[lang()] != null ? v[lang()] : '';
  }
  function visible() { return items.filter(function (it) { return t(it.title); }); }

  if (window.marked) {
    marked.use({
      renderer: {
        image: function () { return ''; },
        html: function (html) { return esc(html); },
        link: function (href, title, text) {
          var ext = /^https?:\/\//i.test(href || '');
          return '<a href="' + esc(href || '') + '"' + (title ? ' title="' + esc(title) + '"' : '') +
            (ext ? ' target="_blank" rel="noopener"' : '') + '>' + text + '</a>';
        }
      }
    });
  }
  /* без marked (CDN недоступний) — простий текст абзацами */
  function md(text) {
    if (window.marked) return marked.parse(text);
    return text.split(/\n{2,}/).map(function (p) { return '<p>' + esc(p) + '</p>'; }).join('');
  }

  function date(iso) {
    if (!iso) return '';
    var d = new Date(iso + 'T00:00:00');
    if (isNaN(d)) return '';
    var fmt = new Intl.DateTimeFormat(lang() === 'en' ? 'en-GB' : 'uk-UA', { day: 'numeric', month: 'long', year: 'numeric' });
    return '<time datetime="' + esc(iso) + '">' + esc(fmt.format(d)) + '</time>';
  }

  function slider(images) {
    var names = Object.keys(images || {});
    if (!names.length) return '';
    var d = dict(), many = names.length > 1;
    var slides = names.map(function (name) {
      return '<figure><img src="' + esc(images[name]) + '" alt="' + esc(name) + '" loading="lazy"><figcaption>' + esc(name) + '</figcaption></figure>';
    }).join('');
    return '<div class="slider">' +
      '<div class="slider__track">' + slides + '</div>' +
      (many
        ? '<button class="slider__btn slider__btn--prev" type="button" data-dir="-1" aria-label="' + esc(d['news.prev'] || '') + '">‹</button>' +
          '<button class="slider__btn slider__btn--next" type="button" data-dir="1" aria-label="' + esc(d['news.next'] || '') + '">›</button>' +
          '<span class="slider__count" aria-hidden="true">1 / ' + names.length + '</span>'
        : '') +
      '</div>';
  }

  /* допис: у стрічці заголовок веде на окрему сторінку новини */
  function post(it, single) {
    var title = esc(t(it.title));
    return '<article class="post">' + date(it.date) +
      (single ? '<h1 class="title">' + title + '</h1>'
              : '<h2><a href="news.html?id=' + encodeURIComponent(it.id) + '">' + title + '</a></h2>') +
      slider(it.images) +
      '<div class="post__body">' + md(t(it.body)) + '</div></article>';
  }

  function render() {
    if (!loaded) return;
    var d = dict(), id = new URLSearchParams(location.search).get('id');
    if (!id) {
      var list = visible();
      page.innerHTML = '<p class="eyebrow">' + esc(d['news.eyebrow'] || '') + '</p>' +
        '<h1 class="title" style="margin-top:14px">' + esc(d['news.title'] || '') + '</h1>' +
        (list.length ? '<div class="feed">' + list.map(function (it) { return post(it, false); }).join('') + '</div>'
                     : '<p class="lead feed__empty">' + esc(d['news.empty'] || '') + '</p>');
      document.title = d['news.metaTitle'] || document.title;
      return;
    }
    var it = visible().filter(function (x) { return x.id === id; })[0];
    var back = '<a class="feed__back" href="news.html">' + esc(d['news.back'] || '') + '</a>';
    page.innerHTML = '<div class="feed">' + back +
      (it ? post(it, true) : '<p class="lead feed__empty">' + esc(d['news.missing'] || '') + '</p>') + '</div>';
    document.title = (it ? t(it.title) + ' — ' : '') + (d['news.metaTitle'] || '');
  }

  /* слайдер: кнопки гортають на ширину кадру, лічильник — за прокруткою (свайп працює нативно) */
  page.addEventListener('click', function (e) {
    var b = e.target.closest('.slider__btn'); if (!b) return;
    var track = b.parentNode.querySelector('.slider__track');
    var dir = Number(b.getAttribute('data-dir'));
    var last = track.scrollLeft + track.clientWidth >= track.scrollWidth - 1;
    if (dir > 0 && last) track.scrollTo({ left: 0 });
    else if (dir < 0 && track.scrollLeft <= 0) track.scrollTo({ left: track.scrollWidth });
    else track.scrollBy({ left: dir * track.clientWidth });
  });
  var pending = false;
  page.addEventListener('scroll', function (e) {
    var track = e.target;
    if (!track.classList || !track.classList.contains('slider__track') || pending) return;
    pending = true;
    requestAnimationFrame(function () {
      pending = false;
      var count = track.parentNode.querySelector('.slider__count'); if (!count) return;
      count.textContent = (Math.round(track.scrollLeft / track.clientWidth) + 1) + ' / ' + track.children.length;
    });
  }, true);

  document.addEventListener('langchange', render);

  fetch('news/news.json')
    .then(function (r) { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (data) {
      items = Array.isArray(data) ? data : [];
      /* стабільні id: явний id → дата → номер; дублікати отримують суфікс */
      var seen = {};
      items.forEach(function (it, i) {
        var id = String(it.id || it.date || i + 1);
        seen[id] = (seen[id] || 0) + 1;
        it.id = seen[id] > 1 ? id + '-' + seen[id] : id;
      });
    })
    .catch(function () { items = []; })
    .then(function () { loaded = true; render(); });
})();
