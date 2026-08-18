#!/usr/bin/env bash
set -euo pipefail

# Install the runtime, SDK and Electron BaseApp required to build AdsPower.
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub \
    org.freedesktop.Platform//24.08 \
    org.freedesktop.Sdk//24.08 \
    org.electronjs.Electron2.BaseApp//24.08

echo "[+] AdsPower prerequisites installed."
