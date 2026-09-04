# sunfang3.github.io OINK Index Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish https://sunfang3.github.io/ as a zh-default bilingual academic index (landing + notes/papers/about) on OINK v1.0.0 from `pgsty/oink-starter`.

**Architecture:** Create `sunfang3/sunfang3.github.io` from the OINK Starter GitHub template and merge it into this workspace without losing `docs/superpowers/`. Delete Docs/Blog/Book before flipping `defaultContentLanguage` to `zh`, so only the home roots need suffix inversion. Landing copy lives in `data/home/{zh,en}.yaml`; three ordinary section roots own the top nav. GitHub Actions Pages is the only host.

**Tech Stack:** Hugo Extended 0.165.0, Go 1.27, Hugo Module `github.com/pgsty/oink v1.0.0`, GitHub Pages. No Node.js.

**Spec:** `docs/superpowers/specs/2026-09-05-sunfang3-github-io-oink-index-design.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `hugo.yaml` | Identity, zh-default languages, Goldmark, outputs, params, module import |
| `go.mod` / `go.sum` | Module path `github.com/sunfang3/sunfang3.github.io`; pin OINK v1.0.0 |
| `data/home/zh.yaml` | Chinese landing: hero, two catalog cards, CTA |
| `data/home/en.yaml` | English landing, same structure |
| `content/_index.md` | Chinese home root (title + description only) |
| `content/_index.en.md` | English home root |
| `content/notes/_index.md` + `_index.en.md` | Textbook catalog + `menus.main` identifier `notes` |
| `content/papers/_index.md` + `_index.en.md` | Paper catalog + identifier `papers` |
| `content/about/_index.md` + `_index.en.md` | About copy + identifier `about` |
| `scripts/verify.rb` | Local production-build contract (Ruby stdlib only) |
| `.github/workflows/github-pages.yaml` | Keep Starter file as-is |
| `.github/workflows/cloudflare-pages.yaml` | Delete |
| `content/docs/`, `content/blog/`, `content/book/` | Delete entire trees |
| `data/home/fr.yaml`, `i18n/fr.yaml`, `**/*.fr.md` | Delete after disabling French |
| `docs/superpowers/` | Keep; never overwrite when importing the template |

Do not add Giscus, analytics, custom logo, custom landing partials, or a software catalog.

**Order note:** Spec lists identity+language before deleting sample surfaces. This plan deletes Docs/Blog/Book *before* the zh-default flip so we do not rename dozens of sample files we are about to throw away. Identity (`baseURL`, module path) still lands first. Home YAML that links to `notes/` lands in the same task as those pages, so `--printPathWarnings` never sees a dead internal path.

**Production build (every later task):**

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
```

Expected: last line contains `Total in`, no WARNING, exit 0.

---

### Task 1: Import OINK Starter and prove the unmodified baseline

**Files:**
- Create (via GitHub template + merge): Starter tree under this workspace
- Keep: `docs/superpowers/specs/`, `docs/superpowers/plans/`

- [ ] **Step 1: Confirm toolchain**

```bash
go version
hugo version
gh auth status
```

Expected:
- `go version go1.27` or newer
- `hugo v0.165.0+extended` or newer Extended (must contain `extended`)
- `gh` authenticated as `sunfang3`

If Hugo is missing or not Extended, install the official Extended 0.165.0 binary (Linux amd64 `.deb` or the matching tarball). Do not use a non-extended Hugo.

- [ ] **Step 2: Create the GitHub repository from the template**

```bash
gh repo create sunfang3.github.io --template pgsty/oink-starter --public --confirm
```

Expected: `https://github.com/sunfang3/sunfang3.github.io` exists. If the name is taken, stop and tell the human; do not pick a different name (user Pages requires this exact repo name).

- [ ] **Step 3: Merge Starter history into this workspace without losing the spec**

This workspace is already a git repo on `master` with only the spec/plan commits. The template repo’s default branch is `main`.

```bash
git branch -m master main
git remote add origin https://github.com/sunfang3/sunfang3.github.io.git
git fetch origin
git merge origin/main --allow-unrelated-histories -m "chore: import pgsty/oink-starter template"
```

If Git reports conflicts, keep `docs/superpowers/**` from HEAD and take Starter files for everything else. Do not discard the spec.

- [ ] **Step 4: Unmodified production build**

```bash
hugo mod graph | grep github.com/pgsty/oink
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
test -f public/index.html && test -f public/zh/index.html && test -f public/fr/index.html
test -d public/docs && test -d public/blog && test -d public/book
```

Expected:
- Graph line contains `github.com/pgsty/oink@v1.0.0` (not a pseudo-version)
- Build exit 0
- English home at `public/index.html`, Chinese at `public/zh/index.html` (Starter still English-default)

- [ ] **Step 5: Commit if the merge did not already include a clean tree**

Only commit if you resolved conflicts or had leftover unstaged files:

```bash
git add -A
git status --short | grep -E 'public/|resources/|\.hugo' && echo "FAIL: build output staged" && exit 1
git commit -m "chore: import oink-starter while keeping planning docs"
```

If `git status` is clean after Step 3–4, skip this commit.

---

### Task 2: Site identity (still English-default)

**Files:**
- Modify: `go.mod`
- Modify: `hugo.yaml` (only `title`, `baseURL`, `params.copyright`)
- Modify: `go.sum` only if `hugo mod tidy` changes it

- [ ] **Step 1: Change the Go module path**

Replace `go.mod` with:

```go
module github.com/sunfang3/sunfang3.github.io

go 1.27.0

require github.com/pgsty/oink v1.0.0
```

```bash
hugo mod tidy
hugo mod graph | grep github.com/pgsty/oink
```

Expected: still `github.com/pgsty/oink@v1.0.0`.

- [ ] **Step 2: Change identity keys in `hugo.yaml`**

At the top of `hugo.yaml`, set:

```yaml
title: &siteTitle 孙方
baseURL: https://sunfang3.github.io/
```

Leave `defaultContentLanguage: en` unchanged in this task.

Under `params.copyright`:

```yaml
  copyright:
    authors: Fang Sun
    from_year: 2026
```

Do not uncomment `github_repo` yet.

- [ ] **Step 3: Warning-strict build**

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
grep -F "孙方" public/index.html
```

Expected: exit 0; `孙方` appears in the English home (temporary; Task 4 splits titles).

- [ ] **Step 4: Commit**

```bash
git add go.mod go.sum hugo.yaml
git commit -m "chore: set site module path, baseURL, and title"
```

---

### Task 3: Remove sample surfaces and disable French

**Files:**
- Delete: `content/docs/` (entire tree)
- Delete: `content/blog/` (entire tree)
- Delete: `content/book/` (entire tree)
- Delete: `content/_index.fr.md`
- Delete: `data/home/fr.yaml`
- Delete: `i18n/fr.yaml`
- Delete: `.github/workflows/cloudflare-pages.yaml`
- Modify: `hugo.yaml` (add `disableLanguages`)
- Modify: `data/home/en.yaml` (hero-only, no docs/blog/book URLs)
- Modify: `data/home/zh.yaml` (hero-only, no docs/blog/book URLs)

Home cards that point at `notes/` cannot be added yet (those pages do not exist). This task uses a hero-only landing so `--printPathWarnings` stays clean.

- [ ] **Step 1: Disable French in `hugo.yaml`**

Immediately after `defaultContentLanguage: en` add:

```yaml
disableLanguages: [fr]
```

Keep the `languages.fr` block declared.

- [ ] **Step 2: Delete sample trees and French files**

```bash
rm -rf content/docs content/blog content/book
rm -f content/_index.fr.md data/home/fr.yaml i18n/fr.yaml
rm -f .github/workflows/cloudflare-pages.yaml
```

- [ ] **Step 3: Replace home data with hero-only copy**

Write `data/home/zh.yaml`:

```yaml
sections: [hero]

hero:
  align: center
  eyebrow: 学习笔记索引
  title_lines:
    - words: [{ text: 孙方 }]
  lead: 教材伴读与前沿论文的入口。正文仍在各自站点，这里只做目录。
```

Write `data/home/en.yaml`:

```yaml
sections: [hero]

hero:
  align: center
  eyebrow: Notes index
  title_lines:
    - words: [{ text: Fang Sun }]
  lead: An index of textbook companions and frontier-paper notes. The writing stays on those sites; this is the door.
```

No `url:` keys. No illustration.

- [ ] **Step 4: Build and assert sample routes are gone**

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
test ! -e public/docs
test ! -e public/blog
test ! -e public/book
test ! -e public/fr
grep -R "href=\"[^\"]*docs/" public/index.html public/zh/index.html && exit 1 || true
```

Expected: build exit 0; those directories absent; no remaining `docs/` links in the two homes.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: drop docs, blog, book, French, and Cloudflare"
```

---

### Task 4: Flip default language to Chinese

**Files:**
- Modify: `hugo.yaml` (languages block and default)
- Modify: `content/_index.md` (becomes Chinese)
- Create: `content/_index.en.md` (former English home)
- Delete: `content/_index.zh.md`

- [ ] **Step 1: Write the failing route check**

After the current (English-default) tree, Chinese home is at `public/zh/index.html`. The contract we want:

```bash
test -f public/index.html
test -f public/en/index.html
test ! -e public/zh
```

Run it against the last build. Expected: `public/en` missing and `public/zh` present — the check fails. Do not “fix” by copying files; fix configuration next.

- [ ] **Step 2: Replace the identity/language section of `hugo.yaml`**

Keep Goldmark, `outputs`, `params.ui`, `module`, and commented integration blocks already in the file. Change the top identity + `languages` block to:

```yaml
title: 孙方
baseURL: https://sunfang3.github.io/
defaultContentLanguage: zh
disableLanguages: [fr]
enableGitInfo: true
enableRobotsTXT: true
enableEmoji: true
timeZone: UTC

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

Do **not** keep `title: &siteTitle` — the two live languages have different titles.

- [ ] **Step 3: Invert home content suffixes**

```bash
git mv content/_index.md content/_index.en.md
git mv content/_index.zh.md content/_index.md
```

Then set the files to:

`content/_index.md`:

```markdown
---
title: 孙方
description: 教材伴读与前沿论文的索引。
---
```

`content/_index.en.md`:

```markdown
---
title: Fang Sun
description: An index of textbook companions and frontier-paper notes.
---
```

Confirm there is no `content/_index.zh.md`.

- [ ] **Step 4: Build and re-run the route check**

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
test -f public/index.html
test -f public/en/index.html
test ! -e public/zh
grep -F "孙方" public/index.html
grep -F "Fang Sun" public/en/index.html
ls public/offline-search-index.zh*.json public/offline-search-index.en*.json
```

Expected: all tests pass; build exit 0.

- [ ] **Step 5: Commit**

```bash
git add hugo.yaml content/_index.md content/_index.en.md
git add -u content/_index.zh.md
git commit -m "feat: make Chinese the default language"
```

---

### Task 5: Landing cards and notes/papers/about

**Files:**
- Modify: `data/home/zh.yaml`
- Modify: `data/home/en.yaml`
- Create: `content/notes/_index.md`
- Create: `content/notes/_index.en.md`
- Create: `content/papers/_index.md`
- Create: `content/papers/_index.en.md`
- Create: `content/about/_index.md`
- Create: `content/about/_index.en.md`

Do not set `type: docs` / `type: blog` / `type: book`. Empty catalogs are the correct v1 body; Task 7 may replace the empty line with cards.

- [ ] **Step 1: Write Chinese section roots**

`content/notes/_index.md`:

```markdown
---
title: 教材伴读
linkTitle: 教材伴读
description: 按教材组织的伴读索引，正文在各自站点。
icon: fa-solid fa-book-open
menus:
  main:
    identifier: notes
    weight: 20
---

按教材组织的伴读索引，正文在各自站点。

还没有公开条目。
```

`content/papers/_index.md`:

```markdown
---
title: 前沿论文
linkTitle: 前沿论文
description: 一篇论文一份笔记的索引，正文在各自站点。
icon: fa-solid fa-file-lines
menus:
  main:
    identifier: papers
    weight: 30
---

一篇论文一份笔记的索引，正文在各自站点。

还没有公开条目。
```

`content/about/_index.md`:

```markdown
---
title: 关于
linkTitle: 关于
description: 这个站点是什么。
icon: fa-solid fa-user
menus:
  main:
    identifier: about
    weight: 40
---

我是孙方。

这个站点是教材伴读与前沿论文的索引；正文仍在各自的仓库里。

GitHub：[sunfang3](https://github.com/sunfang3)
```

- [ ] **Step 2: Write English peers (same identifiers, weights, heading-free bodies)**

`content/notes/_index.en.md`:

```markdown
---
title: Textbook companions
linkTitle: Notes
description: An index of textbook companions. The writing stays on those sites.
icon: fa-solid fa-book-open
menus:
  main:
    identifier: notes
    weight: 20
---

An index of textbook companions. The writing stays on those sites.

No public entries yet.
```

`content/papers/_index.en.md`:

```markdown
---
title: Frontier papers
linkTitle: Papers
description: An index of paper notes. The writing stays on those sites.
icon: fa-solid fa-file-lines
menus:
  main:
    identifier: papers
    weight: 30
---

An index of paper notes. The writing stays on those sites.

No public entries yet.
```

`content/about/_index.en.md`:

```markdown
---
title: About
linkTitle: About
description: What this site is.
icon: fa-solid fa-user
menus:
  main:
    identifier: about
    weight: 40
---

I am Fang Sun.

This site indexes textbook companions and frontier-paper notes; the writing stays in those repositories.

GitHub: [sunfang3](https://github.com/sunfang3)
```

- [ ] **Step 3: Expand home YAML to hero + cards + cta**

`data/home/zh.yaml`:

```yaml
sections: [hero, cards, cta]

hero:
  align: center
  eyebrow: 学习笔记索引
  title_lines:
    - words: [{ text: 孙方 }]
  lead: 教材伴读与前沿论文的入口。正文仍在各自站点，这里只做目录。
  actions:
    - { label: 教材伴读, url: notes/, icon: fa-solid fa-book-open, style: primary }
    - { label: 前沿论文, url: papers/, icon: fa-solid fa-arrow-right, style: ghost }

cards:
  columns: 2
  items:
    - title: 教材伴读
      desc: 按书组织的 Quarto 伴读索引。
      icon: fa-solid fa-book-open
      url: notes/
    - title: 前沿论文
      desc: 一篇论文一份笔记的索引。
      icon: fa-solid fa-file-lines
      url: papers/

cta:
  title: 这是索引，不是第三个笔记仓库。
  text: 正文仍在各自站点。
  label: 关于
  url: about/
  style: primary
```

`data/home/en.yaml`:

```yaml
sections: [hero, cards, cta]

hero:
  align: center
  eyebrow: Notes index
  title_lines:
    - words: [{ text: Fang Sun }]
  lead: An index of textbook companions and frontier-paper notes. The writing stays on those sites; this is the door.
  actions:
    - { label: Notes, url: notes/, icon: fa-solid fa-book-open, style: primary }
    - { label: Papers, url: papers/, icon: fa-solid fa-arrow-right, style: ghost }

cards:
  columns: 2
  items:
    - title: Textbook companions
      desc: An index of Quarto textbook companions.
      icon: fa-solid fa-book-open
      url: notes/
    - title: Frontier papers
      desc: One paper, one note.
      icon: fa-solid fa-file-lines
      url: papers/

cta:
  title: This is an index, not a third notes warehouse.
  text: The writing stays in those repositories.
  label: About
  url: about/
  style: primary
```

- [ ] **Step 4: Warning-strict build and route check**

```bash
hugo --cleanDestinationDir --gc --minify --environment production \
  --printPathWarnings --panicOnWarning
test -f public/notes/index.html
test -f public/en/notes/index.html
test -f public/papers/index.html
test -f public/en/papers/index.html
test -f public/about/index.html
test -f public/en/about/index.html
grep -F "还没有公开条目" public/notes/index.html
grep -F "No public entries yet" public/en/notes/index.html
grep -F "sunfang3" public/about/index.html
grep -R "Project Name" public && exit 1 || true
grep -R "example.org" public && exit 1 || true
```

Expected: build exit 0; all paths exist; no Starter placeholders in `public/`.

- [ ] **Step 5: Commit**

```bash
git add data/home/zh.yaml data/home/en.yaml content/notes content/papers content/about
git commit -m "feat: add notes, papers, and about index pages"
```

---

### Task 6: Local verification script

**Files:**
- Create: `scripts/verify.rb`

This is the repeatable contract for later tasks. Ruby standard library only.

- [ ] **Step 1: Write `scripts/verify.rb`**

```ruby
#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"

ROOT = File.expand_path("..", __dir__)
Dir.chdir(ROOT)

def fail!(message)
  warn "FAIL: #{message}"
  exit 1
end

def ok(message)
  puts "ok  #{message}"
end

def public_path(*parts)
  File.join("public", *parts)
end

graph, status = Open3.capture2("hugo", "mod", "graph")
fail!("hugo mod graph failed") unless status.success?
graph.include?("github.com/pgsty/oink@v1.0.0") || fail!("OINK is not pinned to v1.0.0")
ok("oink@v1.0.0")

build = [
  "hugo",
  "--cleanDestinationDir",
  "--gc",
  "--minify",
  "--environment", "production",
  "--printPathWarnings",
  "--panicOnWarning"
]
fail!("hugo production build failed") unless system(*build)
ok("production build")

{
  "index.html" => true,
  "en/index.html" => true,
  "notes/index.html" => true,
  "en/notes/index.html" => true,
  "papers/index.html" => true,
  "en/papers/index.html" => true,
  "about/index.html" => true,
  "en/about/index.html" => true,
  "llms.txt" => true,
  "robots.txt" => true,
  "zh/index.html" => false,
  "docs/index.html" => false,
  "blog/index.html" => false,
  "book/index.html" => false,
  "fr/index.html" => false
}.each do |rel, should_exist|
  exists = File.exist?(public_path(rel))
  if should_exist
    exists ? ok(rel) : fail!("missing #{rel}")
  else
    exists ? fail!("should not exist #{rel}") : ok("absent #{rel}")
  end
end

%w[zh en].each do |lang|
  hits = Dir.glob(public_path("offline-search-index.#{lang}*.json"))
  hits.empty? ? fail!("missing offline-search-index.#{lang}*.json") : ok(hits.join(", "))
end

needles = {
  "index.html" => "孙方",
  "en/index.html" => "Fang Sun",
  "about/index.html" => "sunfang3",
  "en/about/index.html" => "Fang Sun"
}
needles.each do |rel, text|
  File.read(public_path(rel)).include?(text) ? ok("#{rel} has #{text}") : fail!("#{rel} missing #{text.inspect}")
end

["Project Name", "example.org", "PROJECT-DOCS"].each do |banned|
  hits = Dir.glob("public/**/*.{html,xml,txt,json}").select do |path|
    File.file?(path) && File.read(path).include?(banned)
  end
  fail!("placeholder #{banned.inspect} in #{hits.join(', ')}") unless hits.empty?
end
ok("no starter placeholders")

File.read(public_path("robots.txt")).include?("Allow: /") || fail!("robots.txt is not Allow: /")
ok("robots.txt")

puts "PASS"
```

```bash
chmod +x scripts/verify.rb
```

- [ ] **Step 2: Run the script; it should pass on the Task 5 tree**

```bash
ruby scripts/verify.rb
```

Expected: prints `PASS`, exit 0. If it fails, fix the site or the script (do not weaken assertions that match the spec).

- [ ] **Step 3: Commit**

```bash
git add scripts/verify.rb
git commit -m "test: add Hugo production verification script"
```

---

### Task 7: Seed public catalog entries (optional cards)

**Files:**
- Modify: `content/notes/_index.md` and `_index.en.md` only if a URL returns 200
- Modify: `content/papers/_index.md` and `_index.en.md` only if a URL returns 200

Empty catalogs remain valid. Never add a private repo.

- [ ] **Step 1: Probe candidate public Pages**

```bash
for u in \
  https://sunfang3.github.io/hansen-econometrics-solutions/ \
  https://sunfang3.github.io/hong_econometrics/ \
  https://sunfang3.github.io/schoelkopf-causality-notes/ \
  https://sunfang3.github.io/HDS/ \
  https://sunfang3.github.io/frontier-papers/
 do
  code=$(curl -o /dev/null -s -w "%{http_code}" -L "$u")
  echo "$code $u"
done
```

Also check each public repo’s `homepage` / Pages URL:

```bash
gh repo list sunfang3 --limit 100 --json name,isPrivate,homepage,url \
  --jq '.[] | select(.isPrivate==false) | [.name,.homepage,.url] | @tsv'
```

A candidate counts only if `curl -L` returns **200** (not 404, not a GitHub login page).

- [ ] **Step 2: If none return 200, stop this task after re-running verify**

```bash
ruby scripts/verify.rb
```

Expected: PASS. No commit required if nothing changed.

- [ ] **Step 3: If any return 200, replace the empty line with cards**

Chinese pattern (keep the intro paragraph):

```markdown
按教材组织的伴读索引，正文在各自站点。

- [Hansen Econometrics 习题](https://sunfang3.github.io/hansen-econometrics-solutions/)
- [Hong Econometrics 笔记](https://sunfang3.github.io/hong_econometrics/)
{.cards}
```

English peer must list the **same URLs in the same order**. Do not add software repos (synthAIO, DoubleML.jl, english_academy, wxm).

- [ ] **Step 4: Verify and commit only if files changed**

```bash
ruby scripts/verify.rb
```

If Step 2 made no edits, stop. If cards were added:

```bash
git add content/notes content/papers
git commit -m "feat: list public companion pages in the catalogs"
```

---

### Task 8: Repository links, README, and GitHub Pages

**Files:**
- Modify: `hugo.yaml` (`params.github_repo`, `params.github_branch`)
- Modify: `README.md`
- Modify: `LICENSE` copyright line if it still says a generic Starter holder

- [ ] **Step 1: Enable repository links**

In `hugo.yaml` under `params`, set (uncomment or add):

```yaml
  github_repo: https://github.com/sunfang3/sunfang3.github.io
  github_branch: main
```

- [ ] **Step 2: Replace `README.md`**

````markdown
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
````

- [ ] **Step 3: Verify and commit**

```bash
ruby scripts/verify.rb
git add hugo.yaml README.md LICENSE
git commit -m "chore: enable GitHub repo links and rewrite README"
```

- [ ] **Step 4: Push and enable Pages**

```bash
git push -u origin main
gh api -X PUT repos/sunfang3/sunfang3.github.io/pages \
  -f build_type=workflow \
  || true
```

If the API call fails, set Settings → Pages → Source → GitHub Actions in the browser. Watch the latest run (do not run bare `gh run watch`, which waits on a TTY prompt):

```bash
gh run list --repo sunfang3/sunfang3.github.io --limit 1 --json databaseId,status,conclusion,url
gh run watch "$(gh run list --repo sunfang3/sunfang3.github.io --limit 1 --json databaseId --jq '.[0].databaseId')"
```

Expected: workflow green.

- [ ] **Step 5: Live acceptance (spec checklist)**

Open these on the real host, not localhost:

- https://sunfang3.github.io/
- https://sunfang3.github.io/en/
- https://sunfang3.github.io/notes/
- https://sunfang3.github.io/en/notes/
- https://sunfang3.github.io/papers/
- https://sunfang3.github.io/en/papers/
- https://sunfang3.github.io/about/
- https://sunfang3.github.io/en/about/
- https://sunfang3.github.io/robots.txt
- https://sunfang3.github.io/this-page-does-not-exist (site 404)

Production search indexes are fingerprinted (`offline-search-index.zh.<hash>.json`). Do not request the unhashed path. From the homepage HTML, extract the `offline-search-index` URL the page actually loads and `curl` that URL; it must return 200 JSON.

Confirm: language switch from `/notes/` lands on `/en/notes/`; canonical URLs use `https://sunfang3.github.io/`; `robots.txt` contains `Allow: /`; every catalog outbound link still returns 200.

If the referenced search JSON 404s while HTML works, `baseURL` is wrong — fix `hugo.yaml` / the workflow `--baseURL` and redeploy. Do not “fix” it with `canonifyURLs`.
