#!/usr/bin/env bash
# Build a self-contained offline copy of the Cheat-Sheets MkDocs site.
# Run on a machine with internet + Python + mkdocs-material, then move the
# resulting tarball to the offline machine and extract.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${REPO_ROOT}/cheat-sheets-offline.tar.gz"

echo "[offline-pack] building site in ${REPO_ROOT}"
mkdocs build --clean --strict

echo "[offline-pack] archiving site/"
tar -czf "${OUT}" -C "${REPO_ROOT}" site

echo "[offline-pack] wrote ${OUT}"
echo "[offline-pack] contents:"
tar -tzf "${OUT}" | head -20
echo "..."
echo "[offline-pack] offline usage:"
echo "  1. Copy ${OUT} to the offline machine (USB, scp, internal mirror)."
echo "  2. tar -xzf cheat-sheets-offline.tar.gz"
echo "  3. Open site/index.html in a browser, OR serve it:"
echo "     cd site && python3 -m http.server 8000"
echo "     then open http://localhost:8000"
echo "[offline-pack] search works offline (client-side Lunr + search_index.json)."
