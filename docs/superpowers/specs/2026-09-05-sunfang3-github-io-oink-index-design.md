# sunfang3.github.io — OINK academic index

**Date:** 2026-09-05
**Status:** Approved design
**Repo (to create):** `sunfang3/sunfang3.github.io`
**Public URL:** https://sunfang3.github.io/

## Problem

GitHub user `sunfang3` has no user-level Pages site. Companion notes and paper notes already live in other repositories (mostly Quarto). This repository must become the default site at `https://sunfang3.github.io/` — an index, not a third notes warehouse.

## Decisions

| Decision | Choice | Rejected |
|----------|--------|----------|
| Generator | Hugo Extended + OINK theme (Hugo Module pin v1.0.0) | Treating OINK as a standalone SSG; copying `oink.pgsty.com`; starting from an empty Hugo site |
| Origin | GitHub template from `pgsty/oink-starter` | Hand-assembling files; cloning the theme/docs regression repo |
| Site job | Academic index: textbook companions + frontier papers + About | Migrating Quarto books into this repo; software/app catalog |
| Languages | Chinese default at `/`, English at `/en/` | English default; French enabled; Chinese-only |
| Information architecture | Landing home + three section pages | Docs-as-catalog stubs; Blog in v1 |
| Display name | 孙方 (zh) / Fang Sun (en) | Shared YAML title anchor; `sunfang3` as public title |
| Hosting | GitHub Pages via Starter workflow | Cloudflare Pages; custom domain in v1 |
| Catalog source | Hand-written Markdown cards; public URLs only | GitHub API; custom partial sharing one YAML across home and lists |

## Architecture

OINK is a Hugo theme, not a generator. The generator is Hugo Extended **0.165.0** (Starter/CI pin). Go **1.27** resolves the Hugo Module. Consumer site needs no Node.js.

```
sunfang3.github.io
├── hugo.yaml                 # identity, zh-default bilingual, Goldmark, outputs, module
├── go.mod / go.sum           # module github.com/sunfang3/sunfang3.github.io; oink v1.0.0
├── data/home/zh.yaml         # Chinese landing
├── data/home/en.yaml         # English landing
├── content/
│   ├── _index.md             # zh home root
│   ├── _index.en.md          # en home root
│   ├── notes/_index.md       # + _index.en.md
│   ├── papers/_index.md      # + _index.en.md
│   └── about/_index.md       # + _index.en.md
└── .github/workflows/github-pages.yaml
```

**Keep from Starter:** Goldmark triple (`unsafe`, block attributes, unwrap standalone images), `outputs` (HTML/RSS/markdown/LLMS/print), `go.mod`/`go.sum` pin, GitHub Pages workflow (`fetch-depth: 0`, `GOWORK=off`, `--panicOnWarning`, `--baseURL` from `configure-pages`), neutral logo/favicon until real artwork exists.

**Delete from Starter (all enabled languages together):** `content/docs/`, `content/blog/`, `content/book/`, Cloudflare workflow, French home data and `.fr.md` files after French is disabled. Do not leave a surface in one language only.

**Do not add:** Giscus, Google Analytics, custom logo, custom landing partials, software project cards.

## Language and identity

Starter bilingual profile is English-default. This site inverts it. Do not `cp examples/hugo.bilingual.yaml` and stop; merge from that file then change:

```yaml
title: 孙方
baseURL: https://sunfang3.github.io/
defaultContentLanguage: zh
disableLanguages: [fr]

languages:
  zh:
    label: 简体中文
    locale: zh-CN
    weight: 1
    title: 孙方
    hasCJKLanguage: true
    params:
      description: 教材伴读与前沿论文的索引。
  en:
    label: English
    locale: en-US
    weight: 2
    title: Fang Sun
    params:
      description: An index of textbook companions and frontier-paper notes.
  fr:
    label: Français
    locale: fr-FR
    weight: 3
    title: Fang Sun
```

French stays declared and disabled so leftover `.fr.md` is not published as a default-language page. After French content is deleted, the `fr` language block may remain as in the Starter bilingual profile.

**File suffix rule:** default language = unsuffixed `.md` (Chinese). English = `.en.md`. Never keep both `_index.md` and `_index.zh.md` after the switch — that collision fails a warning-strict build.

`params.copyright.authors` is Fang Sun / 孙方 (language-specific if the theme allows; otherwise the English name). `from_year: 2026`. After the GitHub repository exists, set:

```yaml
params:
  github_repo: https://github.com/sunfang3/sunfang3.github.io
  github_branch: main
```

## Home page

Home content files hold title and description only. Sections live in `data/home/<lang>.yaml`. Composition: `hero`, `cards`, `cta`. Centered hero, no illustration, no metrics, no timeline.

### Chinese (`data/home/zh.yaml`)

- Hero eyebrow: 学习笔记索引
- Hero title: 孙方
- Hero lead: 教材伴读与前沿论文的入口。正文仍在各自站点，这里只做目录。
- Actions: 教材伴读 → `notes/` (primary); 前沿论文 → `papers/` (ghost)
- Cards (2 columns): 教材伴读 → `notes/`; 前沿论文 → `papers/`
- CTA title: 这是索引，不是第三个笔记仓库。
- CTA button: 关于 → `about/`

### English (`data/home/en.yaml`)

Same structure. Title Fang Sun. Lead: *An index of textbook companions and frontier-paper notes. The writing stays on those sites; this is the door.*

Internal `url` values are site paths without a leading slash so OINK prefixes the language.

## Inner pages

Ordinary section roots, not Docs/Blog/Book types. Top nav `menus.main` on each root (and home if required by OINK): 首页, 教材伴读, 前沿论文, 关于 — English labels Home, Notes, Papers, About. Identifiers `notes`, `papers`, `about` must match across languages.

| Path | Content |
|------|---------|
| `/notes/` | Short intro + `{.cards}` list of textbook companions |
| `/papers/` | Short intro + `{.cards}` list of paper notes |
| `/about/` | Three sentences: who, what this site is, GitHub profile link. No long bio. |

Home cards point at these two catalogs, not at individual books. Individual entries appear only on `/notes/` and `/papers/`. Duplicating a featured bookshelf on the home page is out of scope.

## Catalog policy

- Hand-written cards. Adding a companion means editing the list page (and its `.en.md` peer).
- Include only URLs that open without authentication. Private GitHub repos are not v1 entries.
- An empty `/papers/` (or `/notes/`) is a valid ship state: the page exists and states there are no public entries yet. Do not invent placeholder cards or dead links.
- Seed the lists during implementation by checking known public companion Pages (for example public repos such as `hansen-econometrics-solutions` and `hong_econometrics` if their Pages URLs actually resolve). Do not copy a private repo name into a card.

## Navigation and outputs

After deleting Docs/Blog/Book, no remaining page or home card may link to `/docs/`, `/blog/`, or `/book/`. Run a warning-strict build after the deletion.

Keep Starter `outputs` so `index.md`, RSS, print, and `llms.txt` exist. Offline search stays on; the corpus is the index pages only.

## Deployment

1. Create public repository `sunfang3/sunfang3.github.io` from the `pgsty/oink-starter` template (do not delete `.git` from a clone of the original Starter).
2. Place that repository in this workspace (`p0`) while keeping this spec at `docs/superpowers/specs/`.
3. Set Pages source to GitHub Actions.
4. `go.mod` module path: `github.com/sunfang3/sunfang3.github.io`.
5. Delete `.github/workflows/cloudflare-pages.yaml`.
6. Production build:

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
```

CI additionally passes `--baseURL` from `actions/configure-pages` (user site root, no repo subpath). Do not commit `public/`, `resources/`, or module caches.

## Implementation order

Follow OINK’s layered order; do not change identity, languages, content, and brand in one commit.

1. Unmodified Starter previews (`hugo server`).
2. Identity + zh-default bilingual config; warning-strict build passes.
3. Remove Docs/Blog/Book in all languages; fix home data and menus; build passes.
4. Replace home YAML and add notes/papers/about (both languages).
5. Uncomment `github_repo`, push `main`, verify on the real URL.

Preserve this spec file when importing the template.

## Failure modes

| Name | Symptom | Response |
|------|---------|----------|
| Dead catalog link | Card URL 404s or demands login | Do not include the entry |
| Empty catalog | Zero public URLs | Ship the page with explicit empty copy; build must still be warning-free |
| Language suffix collision | `_index.md` and `_index.zh.md` share a URL; CI panics on warning | Default language unsuffixed; English `.en.md` only |
| Wrong `baseURL` | Page opens, search index 404s | Judge by `offline-search-index.zh.json` / `.en.json` request path |
| Local `go.work` in CI | CI does not verify the pinned OINK tag | Keep `GOWORK=off` and `HUGO_MODULE_WORKSPACE=off` |
| Orphan surface link | Deleted Docs/Blog/Book still linked from home or nav | Delete surface, home cards, and menu entries together |

## Verification

Local: `hugo mod graph` shows `github.com/pgsty/oink@v1.0.0`; warning-strict production build; no `public/` in git status.

On https://sunfang3.github.io after deploy:

- `/`, `/en/`, `/notes/`, `/papers/`, `/about/` and English peers
- Language switch lands on the peer page, not always home
- Search JSON fetches succeed
- Canonical URLs, `robots.txt` is `Allow: /`, site 404 page
- Spot-check every catalog outbound link

## Out of scope (v1)

- Moving Quarto companions into this repo
- Software/app catalog (wxm, synthAIO, DoubleML.jl, …)
- Blog, Docs, Book surfaces
- Comments, analytics, custom domain, custom logo
- Auto-generated repo lists
- Translating companion bodies into English (English site is a thin index)

## Success

https://sunfang3.github.io/ opens as 孙方’s bilingual academic index. A reader can reach public textbook companions and public paper notes, or see an honest empty catalog. The site builds with zero Hugo warnings on the pinned OINK release.
