#!/bin/bash
# Installs (or updates) the latest Prayer release into /Applications.
#
#   With GitHub CLI signed in:
#     bash install.sh
#   No tools needed:
#     curl -fsSL https://raw.githubusercontent.com/elnabalawy23-netizen/prayer-for-mac/main/install.sh | bash
set -euo pipefail

REPO="${PRAYER_REPO:-elnabalawy23-netizen/prayer-for-mac}"
APP_NAME="Prayer"
DEST="/Applications/${APP_NAME}.app"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "▸ downloading the latest release of ${REPO}"
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh release download -R "${REPO}" -p 'Prayer-*.zip' -D "${TMP}"
else
  URL="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep -o 'https://[^"]*Prayer-[^"]*\.zip' | head -1)"
  if [ -z "${URL}" ]; then
    echo "✗ Could not find a release asset. For a private repo install GitHub CLI (brew install gh), run 'gh auth login', then rerun." >&2
    exit 1
  fi
  curl -fL "${URL}" -o "${TMP}/Prayer.zip"
fi
ZIP="$(ls "${TMP}"/*.zip | head -1)"

echo "▸ installing to ${DEST}"
pkill -x Prayer 2>/dev/null || true
ditto -x -k "${ZIP}" "${TMP}/unzipped"
rm -rf "${DEST}"
ditto "${TMP}/unzipped/${APP_NAME}.app" "${DEST}"
# The app is signed with a local certificate, not an Apple Developer ID, so clear the quarantine flag
# that would otherwise make Gatekeeper refuse to open a downloaded copy.
xattr -dr com.apple.quarantine "${DEST}" 2>/dev/null || true
open "${DEST}"

echo "✓ Installed ${APP_NAME}. Hover the notch to open it."
echo "  First run on a new Mac: allow Location when macOS asks (or pick a city in Settings → ··· in the panel)."
