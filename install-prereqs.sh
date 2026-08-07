#!/usr/bin/env bash
set -euo pipefail

# Install the Flatpak runtime, SDK and Electron base app required to build adspower-global.
# This is intended to run on a developer machine or in CI (GitHub Actions).

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install --user -y flathub \
    org.freedesktop.Platform//24.08 \
    org.freedesktop.Sdk//24.08 \
    org.electronjs.Electron2.BaseApp//24.08

echo "[+] Prerequisites installed."
