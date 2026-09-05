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

## Deploy

Push `main`. GitHub Actions publishes `public/` to GitHub Pages.
Set **Settings → Pages → Source** to **GitHub Actions**.
