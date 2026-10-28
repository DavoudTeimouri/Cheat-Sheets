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

## Site

Enable GitHub Pages in the repo (Settings → Pages → source: GitHub Actions) once, then the deploy workflow above publishes on every push to `main`.
