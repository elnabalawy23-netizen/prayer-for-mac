#!/bin/bash
# Builds the Swift package and wraps it into build/Prayer.app, signed with a stable local identity when
# one exists (so updates keep their Location permission), ad-hoc otherwise.
# Usage: scripts/build-app.sh [debug|release]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
APP_NAME="Prayer"
EXECUTABLE="PrayerNotch"
BUNDLE_ID="com.omar.prayernotch"
APP="build/${APP_NAME}.app"

echo "▸ swift build -c ${CONFIG}"
swift build -c "${CONFIG}" --product "${EXECUTABLE}" 2>&1 | { grep -Ev "deprecated|SendableClosureCaptures|^\s*[0-9]+ \||^\s*\||^\s*$|^\s*\`-|^\s*:[0-9]+:|^\[" || true; }
BIN="$(swift build -c "${CONFIG}" --show-bin-path)/${EXECUTABLE}"
[ -x "${BIN}" ] || { echo "✗ build failed: ${BIN} missing" >&2; exit 1; }

[ -f build/AppIcon.icns ] || scripts/make-icon.sh

echo "▸ assembling ${APP}"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources/Fonts"
cp "${BIN}" "${APP}/Contents/MacOS/${APP_NAME}"
cp Packaging/Info.plist "${APP}/Contents/Info.plist"
cp build/AppIcon.icns "${APP}/Contents/Resources/AppIcon.icns"
cp Resources/Fonts/*.ttf "${APP}/Contents/Resources/Fonts/"
cp Resources/Fonts/OFL.txt "${APP}/Contents/Resources/Fonts/"
printf 'APPL????' > "${APP}/Contents/PkgInfo"

# Signing identity, in order of preference. A stable identity is what keeps the Location grant across updates.
# Override with IDENTITY="..." or create the local one with scripts/make-signing-cert.sh.
IDENTITIES="$(security find-identity -v -p codesigning 2>/dev/null || true)"
if [ -z "${IDENTITY:-}" ]; then
  for PATTERN in "Developer ID Application" "Apple Development" "${PRAYER_SIGNING_IDENTITY:-Prayer Signing}"; do
    IDENTITY="$(printf '%s\n' "${IDENTITIES}" | awk -F'"' -v p="${PATTERN}" '$2 ~ p {print $2; exit}')"
    [ -n "${IDENTITY}" ] && break
  done
fi

if [ -n "${IDENTITY:-}" ]; then
  echo "▸ codesign with \"${IDENTITY}\""
  EXTRA=""
  case "${IDENTITY}" in "Developer ID Application"*) EXTRA="--options runtime --timestamp" ;; esac
  # shellcheck disable=SC2086
  codesign --force --sign "${IDENTITY}" --identifier "${BUNDLE_ID}" ${EXTRA} "${APP}"
else
  echo "▸ codesign ad-hoc (no identity found; run scripts/make-signing-cert.sh so updates keep their permissions)"
  codesign --force --sign - --identifier "${BUNDLE_ID}" "${APP}"
fi

codesign --verify --strict "${APP}"
echo "  requirement: $(codesign -d -r- "${APP}" 2>&1 | sed -n 's/^designated => //p')"
echo "✓ ${APP}"
