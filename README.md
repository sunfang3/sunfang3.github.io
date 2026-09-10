# 孙方 / Fang Sun

Personal academic index: https://sunfang3.github.io/

Built with [OINK](https://oink.pgsty.com/) (Hugo Module v1.0.0) from
[oink-starter](https://github.com/pgsty/oink-starter). Chinese is the
default language (`/`); English lives at `/en/`.

## Preview

Requires Git, Go 1.27+, and Hugo Extended 0.165.0+.

```bash
hugo server
```

Open http://localhost:1313/

## Production build

```bash
ruby scripts/verify.rb
```

## Synchronize the catalogs

The catalog source of truth is `data/catalog.yaml`. It contains the polished
Chinese and English labels for existing sites. The script queries every GitHub
Pages site owned by `sunfang3`, removes sites whose Pages deployment no longer
exists, and rewrites the marked catalog blocks.

```bash
ruby scripts/sync_catalog.rb
ruby scripts/verify.rb
```

To synchronize, verify, commit the catalog source and generated pages, and
deploy them in one command, run this from a clean `main` branch:

```bash
ruby scripts/sync_catalog.rb --publish
```

For a future site, add the GitHub topic `academic-notes` or `academic-papers`.
The next sync includes it automatically; it initially uses the repository name
as its label. Add an entry to `data/catalog.yaml` when a polished bilingual
label is needed.

Use `ruby scripts/sync_catalog.rb --check` in automation to fail when the
committed catalogs are stale.

## Deploy

Push `main`. GitHub Actions publishes `public/` to GitHub Pages.
Set **Settings → Pages → Source** to **GitHub Actions**.
