# willowypanda-custom-flathub

A shared, signed Flatpak repository for applications packaged by willowypanda.

The repository is designed to host one application per top-level directory. The current application is:

```text
adspower/
```

Future applications such as `wechat/` can reuse the generic workflows in `.github/workflows/build-app.yml` and `.github/workflows/upload-app.yml`.

## Shared R2 repository

Repository name:

```text
willowypanda-custom-flathub
```

Public repository URL:

```text
https://pub-679acc1c8310441ab00c00f2c8dae9a4.r2.dev
```

Add the signed remote on a new computer:

```bash
flatpak --user remote-add \
  willowypanda-custom-flathub \
  https://pub-679acc1c8310441ab00c00f2c8dae9a4.r2.dev/willowypanda-custom-flathub.flatpakrepo
```

Install AdsPower:

```bash
flatpak --user install -y willowypanda-custom-flathub com.adspower.global
```

The Freedesktop runtime and Electron BaseApp are provided by Flathub:

```bash
flatpak --user remote-add --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
```

## Layout

```text
adspower/
  build-flatpak.sh
  download-latest.sh
  install-prereqs.sh
  adspower_global-wrapper
  com.adspower.global.desktop
  com.adspower.global.metainfo.xml
  flathub.json
  docs/
.github/workflows/
  build-app.yml
  upload-app.yml
  build-adspower.yml
  upload-adspower.yml
  trigger-adspower.yml
```

`build-app.yml` and `upload-app.yml` contain reusable application-independent logic. The `*-adspower.yml` workflows provide AdsPower-specific parameters.

## AdsPower local build

```bash
cd adspower
./install-prereqs.sh
./download-latest.sh
./build-flatpak.sh
```

AdsPower keeps App ID `com.adspower.global` and uses the tested restricted permissions, including `--device=dri` but not `--device=all`, `--device=usb`, `org.freedesktop.Flatpak`, or `org.freedesktop.secrets`.

## GitHub Actions secrets

The workflows expect these repository secrets:

```text
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_BUCKET
R2_PUBLIC_URL
FLATPAK_GPG_PRIVATE_KEY
FLATPAK_GPG_KEY_ID
FLATPAK_GPG_PASSPHRASE
```

Never commit private keys, passphrases, or R2 credentials.

## License

Packaging scripts are provided under the MIT license.
