#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional flags and .deb path.
NO_BUNDLE=false
DEB_ARG=""
for arg in "$@"; do
    case "${arg}" in
        --no-bundle) NO_BUNDLE=true ;;
        -*) echo "[!] Unknown option: ${arg}" >&2; exit 1 ;;
        *) DEB_ARG="${arg}" ;;
    esac
done

# If a .deb path is provided, use it; otherwise use deb_download/.
DEB="${DEB_ARG:-${PROJECT_DIR}/deb_download/AdsPower-Global-*-x64.deb}"

# Determine basename and version from the actual .deb file
if [ -f "${DEB}" ]; then
    DEB_BASENAME="$(basename "${DEB}" .deb)"
else
    # Try glob
    shopt -s nullglob
    candidates=("${PROJECT_DIR}/deb_download"/AdsPower-Global-*-x64.deb)
    shopt -u nullglob
    if [ ${#candidates[@]} -eq 0 ]; then
        echo "[!] No .deb found. Run ./download-latest.sh first, or pass a .deb path." >&2
        exit 1
    fi
    DEB="${candidates[-1]}"
    DEB_BASENAME="$(basename "${DEB}" .deb)"
fi

# e.g. AdsPower-Global-8.7.23-x64 -> 8.7.23
VERSION="${DEB_BASENAME#AdsPower-Global-}"
VERSION="${VERSION%-x64}"
APP_ID="com.adspower.global"

EXTRACT_DIR="/tmp/adspower-flatpak-deb_extracted"
BUILD_DIR="${PROJECT_DIR}/build"
REPO_DIR="${PROJECT_DIR}/repo"
STATE_DIR="${PROJECT_DIR}/.flatpak-builder"
MANIFEST="${PROJECT_DIR}/${APP_ID}.json"

mkdir -p "${BUILD_DIR}" "${REPO_DIR}" "${STATE_DIR}"

echo "[+] Using .deb: ${DEB}"
echo "[+] Version: ${VERSION}"

if [ ! -f "${DEB}" ]; then
    echo "[!] .deb not found: ${DEB}" >&2
    exit 1
fi

echo "[+] Extracting .deb package to ${EXTRACT_DIR}..."
rm -rf "${EXTRACT_DIR}"
mkdir -p "${EXTRACT_DIR}"
dpkg-deb -x "${DEB}" "${EXTRACT_DIR}/"
dpkg-deb -e "${DEB}" "${EXTRACT_DIR}/DEBIAN"

# Flatpak-builder manifest expects a local "deb_extracted" directory.
ln -sfn "${EXTRACT_DIR}" "${PROJECT_DIR}/deb_extracted"

echo "[+] Writing Flatpak manifest ${MANIFEST}..."
cat > "${MANIFEST}" <<'MANIFEST'
{
    "app-id": "com.adspower.global",
    "runtime": "org.freedesktop.Platform",
    "runtime-version": "24.08",
    "sdk": "org.freedesktop.Sdk",
    "base": "org.electronjs.Electron2.BaseApp",
    "base-version": "24.08",
    "command": "adspower_global",
    "separate-locales": false,
    "finish-args": [
        "--share=ipc",
        "--socket=x11",
        "--socket=wayland",
        "--socket=pulseaudio",
        "--share=network",
        "--device=dri",
        "--filesystem=~/Downloads:rw",
        "--filesystem=~/Documents/Adspower:create",
        "--filesystem=xdg-run/pipewire-0",
        "--filesystem=xdg-config/gtk-3.0:ro",
        "--filesystem=xdg-config/gtk-4.0:ro",
        "--talk-name=org.freedesktop.Notifications",
        "--env=ELECTRON_ENABLE_LOGGING=1",
        "--env=ELECTRON_DISABLE_SANDBOX=1",
        "--env=CHROME_DEVEL_SANDBOX=",
        "--env=GTK_USE_PORTAL=1"
    ],
    "modules": [
        {
            "name": "adspower-global",
            "buildsystem": "simple",
            "build-commands": [
                "mkdir -p /app/opt/AdsPower_Global",
                "cp -r \"opt/AdsPower Global/\"* /app/opt/AdsPower_Global/",
                "chmod -R u+w /app/opt/AdsPower_Global",
                "install -Dm755 adspower_global-wrapper /app/bin/adspower_global",
                "install -Dm644 com.adspower.global.desktop /app/share/applications/com.adspower.global.desktop",
                "install -Dm644 com.adspower.global.metainfo.xml /app/share/metainfo/com.adspower.global.metainfo.xml",
                "for s in 16 24 32 48 64 128 256 512; do if [ -f \"usr/share/icons/hicolor/${s}x${s}/apps/adspower_global.png\" ]; then install -Dm644 \"usr/share/icons/hicolor/${s}x${s}/apps/adspower_global.png\" /app/share/icons/hicolor/${s}x${s}/apps/com.adspower.global.png; fi; done"
            ],
            "sources": [
                {
                    "type": "dir",
                    "path": "deb_extracted"
                },
                {
                    "type": "file",
                    "path": "adspower_global-wrapper"
                },
                {
                    "type": "file",
                    "path": "com.adspower.global.desktop"
                },
                {
                    "type": "file",
                    "path": "com.adspower.global.metainfo.xml"
                }
            ]
        }
    ]
}
MANIFEST

chmod +x "${PROJECT_DIR}/adspower_global-wrapper"

# Prefer host flatpak-builder; fall back to the Flathub org.flatpak.Builder app.
FB="flatpak-builder"
if ! command -v "${FB}" >/dev/null 2>&1; then
    if flatpak info org.flatpak.Builder >/dev/null 2>&1; then
        FB="flatpak run org.flatpak.Builder"
    else
        echo "[!] flatpak-builder is not installed. Run ./install-prereqs.sh first." >&2
        exit 1
    fi
fi

echo "[+] Building Flatpak..."
cd "${PROJECT_DIR}"
BUILDER_GPG_ARGS=""
if [ -n "${FLATPAK_GPG_KEY_ID:-}" ]; then
    BUILDER_GPG_ARGS="--gpg-sign=${FLATPAK_GPG_KEY_ID}"
    echo "[+] Signing exported Flatpak commits with GPG key ${FLATPAK_GPG_KEY_ID}"
fi
${FB} ${BUILDER_GPG_ARGS} --force-clean --state-dir="${STATE_DIR}" --repo="${REPO_DIR}" "${BUILD_DIR}" "${MANIFEST}"

if [ "${NO_BUNDLE}" = true ]; then
    echo "[+] Bundle creation skipped; OSTree repository is ready: ${REPO_DIR}"
else
    echo "[+] Creating single-file bundle..."
    flatpak build-bundle "${REPO_DIR}" "${PROJECT_DIR}/adspower-global-${VERSION}.flatpak" "${APP_ID}"
    echo "[+] Done. Bundle: ${PROJECT_DIR}/adspower-global-${VERSION}.flatpak"
fi

# Output a JSON summary for CI parsing
printf '{"version":"%s","bundle":"%s/adspower-global-%s.flatpak"}\n' "${VERSION}" "${PROJECT_DIR}" "${VERSION}"
