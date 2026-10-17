/* ГО «Життєдайна»: перемикання мов UA/EN + мобільне меню «|||».
   Переклади — у i18n/uk.js та i18n/en.js (window.I18N.<мова>).
   Розмітка: data-i18n="ключ" (текст), data-i18n-attr="alt:ключ;aria-label:ключ" (атрибути).
   Мова: ?lang=en → localStorage → мова браузера → uk. */
(function () {
  /* ---- мобільне меню ---- */
  var header = document.querySelector('.header');
  var burger = document.querySelector('.burger');
  function setMenu(open) {
    header.classList.toggle('is-open', open);
    burger.setAttribute('aria-expanded', String(open));
  }
  if (header && burger) {
    burger.addEventListener('click', function () { setMenu(!header.classList.contains('is-open')); });
    document.querySelectorAll('.nav a').forEach(function (a) { a.addEventListener('click', function () { setMenu(false); }); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') setMenu(false); });
    window.matchMedia('(min-width: 1101px)').addEventListener('change', function (m) { if (m.matches) setMenu(false); });
  }

  /* ---- мови ---- */
  var SUPPORTED = ['uk', 'en'], KEY = 'zd-lang';
  function pick() {
    var q = new URLSearchParams(location.search).get('lang');
    if (SUPPORTED.indexOf(q) > -1) return q;
    try { var s = localStorage.getItem(KEY); if (SUPPORTED.indexOf(s) > -1) return s; } catch (e) {}
    var n = (navigator.language || '').slice(0, 2).toLowerCase();
    return SUPPORTED.indexOf(n) > -1 ? n : 'uk';
  }
  function apply(lang) {
    var d = (window.I18N || {})[lang]; if (!d) return;
    document.documentElement.lang = lang;
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var v = d[el.getAttribute('data-i18n')]; if (typeof v === 'string') el.textContent = v;
    });
    document.querySelectorAll('[data-i18n-attr]').forEach(function (el) {
      el.getAttribute('data-i18n-attr').split(';').forEach(function (pair) {
        var p = pair.split(':'), attr = (p[0] || '').trim(), v = d[(p[1] || '').trim()];
        if (attr && typeof v === 'string') el.setAttribute(attr, v);
      });
    });
    if (d['meta.title']) document.title = d['meta.title'];
    var m = document.querySelector('meta[name="description"]');
    if (m && d['meta.description']) m.setAttribute('content', d['meta.description']);
    document.querySelectorAll('[data-lang]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.getAttribute('data-lang') === lang));
    });
    try { localStorage.setItem(KEY, lang); } catch (e) {}
  }
  document.addEventListener('click', function (e) {
    var b = e.target.closest('[data-lang]'); if (!b) return;
    e.preventDefault(); apply(b.getAttribute('data-lang'));
  });
  apply(pick());
})();
