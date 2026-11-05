# site
WEB site for non profit organization

Server-rendered Rails app with SQLite: HAML views, Rails i18n, Propshaft and importmap for assets, Turbo and Stimulus for the frontend. There is no Node or JS build step.

## Layout

| Path | Contents |
|---|---|
| `app/views/` | HAML: `pages/` (home sections), `news/`, `admin/`, `layouts/`, `shared/` |
| `app/assets/` | Images, the icon sprite (`icons.svg`), self-hosted Roboto and stylesheets |
| `app/javascript/controllers/` | Stimulus controllers |
| `config/locales/` | All text: `site.*.yml` (uk, en), `admin.uk.yml`, `models.uk.yml` |
| `storage/` | SQLite database and uploaded files (not in git) |
| `db/seed_files/reports/` | PDFs imported into a new database |

Site text lives in `config/locales/site.uk.yml` and `site.en.yml`, which must keep the same keys (a test checks this). News and reports live in the database.

## Local setup

Requires Ruby 4.0.1.

```sh
bundle install
bin/rails db:setup                                # creates the database, imports reports, adds sample news
bin/rails admin:create EMAIL=name@example.org     # prompts for a password (12+ characters)
bin/rails server
```

The site is at http://localhost:3000 and the backoffice at http://localhost:3000/admin.

```sh
bin/rails test          # models, controllers, pages
bin/rails test:system   # browser behaviour; needs Chrome
```

## Pages and API

| URL | Purpose |
|---|---|
| `/`, `/news`, `/news/:id` | Site pages |
| `/admin/session/new` | Backoffice login |
| `/admin/news` | News list and editor, with Markdown preview and gallery |
| `/admin/reports` | Report upload, titles and ordering |
| `GET /api/news`, `GET /api/news/:id` | News in the current language as JSON, with Markdown bodies |
| `GET /api/reports` | Reports in the current language as JSON |

The language comes from `?lang=uk|en`, then the saved `lang` cookie, then the browser's language, then Ukrainian. The API follows the same rules. News with no title in the current language is hidden in that language. The backoffice is Ukrainian only.

The backoffice session is a JWT in an HttpOnly cookie that lasts 12 hours. There is no sign-up: admins are created with `bin/rails admin:create`. `bin/rails admin:password EMAIL=...` changes a password and ends that admin's sessions; logging out only clears that browser's cookie.

## Configuration

| Env var | Default | Purpose |
|---|---|---|
| `SECRET_KEY_BASE` | | Required in production; signs sessions and file links. Generate with `bin/rails secret` |
| `MAX_IMAGE_SIZE_MB` | 10 | Upload limit for gallery images (JPEG, PNG, WebP) |
| `MAX_PDF_SIZE_MB` | 20 | Upload limit for reports |
| `MAX_IMAGES_PER_UPLOAD` | 10 | Photos accepted in one gallery upload |

Puma refuses any request larger than these limits allow, before it reaches the app (`config/puma.rb`). Restart after changing them.

## Privacy

People may visit this site from monitored devices, so public pages set no cookies unless a language is chosen, load nothing from other sites (Roboto is self-hosted), and send a strict Content Security Policy. Gallery photos are stored under neutral filenames. Keep it that way when adding scripts, fonts, embeds or analytics.

## Deployment

```sh
docker build -t lifegiving .
docker run -d -p 80:80 -e SECRET_KEY_BASE=... -v lifegiving-storage:/rails/storage --name lifegiving lifegiving
docker exec -it lifegiving bin/rails admin:create EMAIL=name@example.org
```

- **Back up the `/rails/storage` volume.** It holds all news, reports and uploaded files, and they are lost if it is removed.
- **Run behind an HTTPS proxy.** The app assumes TLS ends at the proxy: it doesn't redirect plain HTTP itself, and the login cookie only works over HTTPS.
- **Run one server process.** The login rate limit is kept in memory per process.
- The app can't run on GitHub Pages. `CNAME` is left over from that setup and can go once the site has moved.
