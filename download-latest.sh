#!/usr/bin/env bash
set -euo pipefail

# Download the latest AdsPower Global Linux .deb from the official download page.
# Extracts the latest version string from the HTML and fetches the corresponding .deb.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="${PROJECT_DIR}/deb_download"
mkdir -p "${DOWNLOAD_DIR}"

DOWNLOAD_PAGE="https://www.adspower.com/download"

HTML_FILE="$(mktemp)"
trap 'rm -f "${HTML_FILE}"' EXIT

echo "[+] Fetching download page: ${DOWNLOAD_PAGE}"
curl -L -s --max-time 30 "${DOWNLOAD_PAGE}" > "${HTML_FILE}"

# Find the latest linux-x64-global .deb URL embedded in the page.
URL="$(python3 -c "
import re, sys
with open('${HTML_FILE}') as f:
    text = f.read()
urls = re.findall(r'https://version\.adspower\.net/software/linux-x64-global/[^\"<>\s]+\.deb', text)
print(sorted(set(urls), key=lambda u: [int(x) for x in u.split('/')[5].split('.')])[-1] if urls else '')
")"

if [ -z "${URL}" ]; then
    echo "[!] Could not find Linux x64 .deb URL on ${DOWNLOAD_PAGE}" >&2
    exit 1
fi

# Extract version from URL, e.g. .../8.7.23/AdsPower-Global-8.7.23-x64.deb
VERSION="$(echo "${URL}" | sed -E 's#.*/([0-9]+\.[0-9]+\.[0-9]+)/AdsPower-Global-\1-x64\.deb#\1#')"

if [ -z "${VERSION}" ] || [ "${VERSION}" = "${URL}" ]; then
    echo "[!] Could not extract version from URL: ${URL}" >&2
    exit 1
fi

DEB_FILE="${DOWNLOAD_DIR}/AdsPower-Global-${VERSION}-x64.deb"

echo "[+] Latest version: ${VERSION}"
echo "[+] Downloading: ${URL}"
curl -L --progress-bar -o "${DEB_FILE}" "${URL}"

echo "[+] Saved: ${DEB_FILE}"

# Print a single-line JSON summary for CI parsing
printf '{"version":"%s","url":"%s","deb_file":"%s"}\n' "${VERSION}" "${URL}" "${DEB_FILE}"
