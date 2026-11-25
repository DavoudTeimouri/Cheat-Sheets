# Contributing

## Add a new troubleshooting sheet

1. Create the canonical sheet: `<Topic>/Generic/<topic>.md` at repo root (e.g. `Linux/Generic/linux.md`)
2. Add a symlink so the site indexes it: `docs/<Topic>/<topic>.md` → `../../<Topic>/Generic/<topic>.md`
3. Add a nav entry to `mkdocs.yml`
4. Use the template: symptom → likely cause → fix (commands) → quick self-check
5. End with a `ponytail:` scope ceiling (what’s intentionally out of scope)
6. Open a PR against `main`. The MkDocs site deploys automatically via GitHub Pages.

Or use the **New troubleshooting entry** issue template — a maintainer will turn it into a sheet.

## File layout

```
<Topic>/Generic/<topic>.md   # canonical sheet (one per topic)
docs/<Topic>/<topic>.md      # symlink to the canonical sheet (for the site)
mkdocs.yml                   # site config + search
.github/workflows/deploy.yml # builds + deploys to GitHub Pages
.github/ISSUE_TEMPLATE/troubleshooting.md  # submission form
```

## Search

The published site (GitHub Pages) has full-text search across every sheet — `/?q=` or the search bar in the header.

## Offline version (air-gapped)

The entire cheat-sheet site is available offline:

1. On a machine with internet access, run:
   ```bash
   bash scripts/offline_pack.sh
   ```
   This builds the MkDocs site and creates `cheat-sheets-offline.tar.gz`.

2. Copy `cheat-sheets-offline.tar.gz` to the offline machine (USB, scp, internal mirror).

3. Extract and open:
   ```bash
   tar -xzf cheat-sheets-offline.tar.gz
   # Option A: open directly in a browser
   open site/index.html
   # Option B: serve locally
   cd site && python3 -m http.server 8000
   # then open http://localhost:8000
   ```

The search bar works offline (built with MkDocs Material + Lunr.js, pre-built search index). No server or internet required.

## Site

Enable GitHub Pages in the repo (Settings → Pages → source: GitHub Actions) once, then the deploy workflow above publishes on every push to `main`.
