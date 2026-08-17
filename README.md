# flatpak-adspower

将 AdsPower Global Linux `.deb` 转换成 Flatpak，并自动发布到 GitHub Release 和 Cloudflare R2 Flatpak OSTree 仓库。

构建流程优先发布 R2 OSTree 仓库；GitHub Release 的单文件 `.flatpak` 是独立的可选步骤，打包超时不会阻止 R2 更新。

## Cloudflare R2

本项目使用共享 R2 bucket 托管多个 Flatpak 应用。当前 AdsPower 的 R2 remote URL 是：

```text
https://pub-679acc1c8310441ab00c00f2c8dae9a4.r2.dev
```

用户添加 remote：

```bash
flatpak remote-add --user adspower-r2 \
  https://pub-679acc1c8310441ab00c00f2c8dae9a4.r2.dev/
```

首次测试若仓库未配置 GPG 签名，可使用：

```bash
flatpak remote-add --user --no-gpg-verify adspower-r2 \
  https://pub-679acc1c8310441ab00c00f2c8dae9a4.r2.dev/
```

正式发布前应增加 OSTree/GPG 签名。

GitHub Actions 所需 Secrets：

```text
R2_ACCOUNT_ID
R2_ACCESS_KEY_ID
R2_SECRET_ACCESS_KEY
R2_BUCKET
R2_PUBLIC_URL
```

不要把密钥提交到仓库。

## Workflows

### `build-release.yml`

每 6 小时检查 AdsPower 下载页，也支持手动触发。发现新版本后：

1. 下载最新 `.deb`；
2. 构建 Flatpak；
3. 创建 GitHub Release；
4. 上传 bundle artifact；
5. 自动调用 `upload-r2.yml`。

版本标签格式：

```text
v<AdsPower版本>-<打包配置修订号>
```

例如：

```text
v8.7.23-1
```

相同上游版本强制重新打包时，修订号会递增；也可以通过 `force_pkg_rev` 指定。

### `upload-r2.yml`

这是可复用 workflow。它会：

1. 下载构建 workflow 生成的 Flatpak bundle；
2. 下载 R2 中现有的 OSTree 仓库；
3. 导入新 bundle；
4. 保留同一 bucket 中的其他应用；
5. 更新 OSTree summary；
6. 同步完整仓库回 R2；
7. 验证公开的 `summary` 文件。

未来其他应用只需构建 bundle 后复用该 workflow。

## 手动构建

```bash
./install-prereqs.sh
./download-latest.sh
./build-flatpak.sh
```

## Flathub 准备

项目保留了以下 Flathub 相关文件：

- `com.adspower.global.desktop`
- `com.adspower.global.metainfo.xml`
- `flathub.json`
- `adspower_global-wrapper`

未来提交前请参考：

https://docs.flathub.org/docs/for-app-authors/submission

AdsPower 本身是专有软件；本仓库只包含构建和发布脚本。

## License

Packaging scripts are provided under the MIT license.

Repository: https://github.com/willowypanda/flatpak-adspower

