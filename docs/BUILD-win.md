# BUILD-win.md — 思谛 STDeel Windows 桌面版构建 / 打包 / 发布记录与指南

> 本文件由 AGENTS.md 规则驱动：Windows 桌面版构建流程单独记录于此，随 `feature/windows-support` 分支维护（分支禁止合并 `main`）。
> 所有泛用类规则（版本号、Release/Pre-Release 判定、产物命名、代码同步）与 Android 版一致，见 `docs/BUILD.md` 与根 `AGENTS.md`。
> 最新一次成功的构建过程见底部「累计记录」。

## 一、平台差异说明（Windows 适配点）

本项目为拍照识题 + AI 解题移动应用，Windows 桌面版在 `feature/windows-support` 分支做了最小适配：

| 模块 | Android 行为 | Windows 行为 |
| --- | --- | --- |
| 首页「拍照识题」 | 调起系统相机 | 改为「选择图片文件」，走文件选择器（`image_picker` Windows 实现） |
| 本地通知（`notification_service.dart`） | `flutter_local_notifications` 推送 | **无 Windows 实现**，`Platform.isWindows` 时初始化/展示全部跳过 |
| 应用内更新（`update_service.dart`） | 下载 APK + MethodChannel 拉起系统安装器 | 匹配 `.exe` 资产，下载后 `Process.start` 启动安装器 |
| 竖屏锁定（`main.dart`） | `setPreferredOrientations` | Windows 跳过 |

## 二、构建方式（关键：Linux 无法原生构建 Windows）

`flutter build windows` 需要 **Windows 工具链（Visual Studio + MSVC + Windows SDK）**，Linux 沙箱无法交叉编译。
因此 Windows 版采用 **GitHub Actions windows-latest runner** 构建，workflow 已入库：
- 文件：`.github/workflows/build-windows.yml`
- 触发：push 到 `feature/windows-support`，或手动 `workflow_dispatch`
- 流程：安装 Flutter 3.47.1 → `flutter pub get` → `flutter build windows --release` → Inno Setup 打包安装器 → 上传 artifact

手动触发：
```bash
gh workflow run build-windows.yml --repo IFFCheckPass/STDeel --ref feature/windows-support
# 查看状态
gh run list --repo IFFCheckPass/STDeel --workflow build-windows.yml
```

## 三、安装器打包（Inno Setup）

- 脚本：`scripts/windows_installer.iss`
- 产物：`build/windows/installer/stdeel-setup-<版本号>.exe`
- 关键点：
  - **Release 目录必须用绝对路径传入**（`/DReleaseDir=...`），.iss 内相对路径 `..\..\build\...` 在 Actions 上会解析失败报 "No files found"。
  - 语言文件：只保留 `compiler:Default.isl`（choco 版 Inno Setup 不带 `ChineseSimplified.isl`，引用会编译失败）。
  - 版本号从 `pubspec.yaml` 读取，经 `/DMyAppVersion` 传入。

```powershell
$ver = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value
$rel = (Resolve-Path build\windows\x64\runner\Release).Path
iscc /DMyAppVersion=$ver "/DReleaseDir=$rel" scripts/windows_installer.iss
```

## 四、发布到 GitHub Releases

```bash
# 安装器与 APK 上传到同一版本 tag；0.7.0 < 1.0.0 → Pre-Release
gh release upload v<版本号> --repo IFFCheckPass/STDeel stdeel-setup-<版本号>.exe
```

## 五、累计记录

### v0.7.0（✅ 已成功构建并发布 Windows 安装器）
- **版本**：`pubspec.yaml version: 0.7.0+17`（与 Android 版一致）。
- **功能**：Windows 桌面版适配（通知/更新/选图/竖屏平台处理）+ GitHub Actions 构建链 + Inno Setup 安装器。
- **工具链**：GitHub Actions `windows-latest`（自带 VS2022/MSVC）、Flutter 3.47.1 stable（`subosito/flutter-action`）、Inno Setup 6.7.1（choco）。
- **构建**：首次 `flutter build windows --release` 约 115-151s（含插件原生编译）。产物 `build\windows\x64\runner\Release\`（stdeel.exe + dartjni.dll + flutter_windows.dll + data/ + flutter_assets/）。
- **安装器**：`stdeel-setup-0.7.0.exe`，15.4MB（lzma2 压缩）。
- **踩坑记录**：
  1. `.iss` 用相对路径 `..\..\build\windows\x64\runner\Release\*` → Inno Setup 报 "No files found matching ... scripts\..\..\build\..."（相对 .iss 目录解析混乱）。**修复：绝对路径 `/DReleaseDir=` 传入**。
  2. `[Languages]` 引用 `ChineseSimplified.isl` → choco 安装的 Inno Setup 无该文件，编译失败。**修复：仅保留默认英文**。
  3. `workflow_dispatch` 触发被 token 权限拒绝（HTTP 403），但 **push 到分支会自动触发**，无需手动 dispatch。
- **发布**：`gh release upload v0.7.0 stdeel-setup-0.7.0.exe`（与 `app-0.7.0.apk` 同一 Pre-Release）。
  - 链接：https://github.com/IFFCheckPass/STDeel/releases/tag/v0.7.0
- **收尾**：Windows 产物上传后删除本地下载副本（`win_artifact/`），保持工作区干净。

### v0.7.1（✅ 已成功构建并发布 Windows 安装器）
- **版本**：`pubspec.yaml version: 0.7.1+18`（与 Android 版一致）。
- **本次功能**：
  1. 窗口标题 `windows/runner/main.cpp`：`window.Create(L"stdeel", ...)` → `L"\u601D\u8C16"`（思谛，用 Unicode 转义避免源码编码问题）。
  2. 应用图标：用安卓端 `assets/icon/app_icon.png`（1024×1024）经 Python PIL 重新生成多尺寸 `windows/runner/resources/app_icon.ico`（16/24/32/48/64/128/256），替换 Flutter 默认图标；Runner.rc 引用路径不变。
  3. 字体：内置 HarmonyOS Sans SC Medium 于 `assets/fonts/`，`pubspec.yaml` 注册 + 主题 `fontFamily`，Windows 端 Flutter 同样从 assets 加载，与安卓一致。
- **构建**：push 到 `feature/windows-support` 自动触发 `build-windows` workflow，约 **4m59s** 成功（Flutter 3.47.1 windows-latest）。
- **安装器**：`stdeel-setup-0.7.1.exe`，20.4MB（含字体 assets，比 0.7.0 的 15.4MB 大）。
- **下载产物**（artifact → 本地 → 上传 Release）：
  - `gh run download <run-id> -n stdeel-windows-installer -D <dir>`（代理环境下可能很慢）；
  - 备选（更快）：`gh api repos/.../actions/artifacts/<id>/zip` 配合 `curl -L -H "Authorization: Bearer $(gh auth token)"` 直接下载 zip。
- **发布**：`gh release upload v0.7.1 stdeel-setup-0.7.1.exe`（与 `app-0.7.1.apk` 同一 Pre-Release；0.7.1 < 1.0.0 → Pre-Release）。
  - 链接：https://github.com/IFFCheckPass/STDeel/releases/tag/v0.7.1
- **收尾**：删除本地下载副本，保持工作区干净。

### v0.7.2（✅ 已成功构建并发布 Windows 安装器）
- **版本**：`pubspec.yaml version: 0.7.2+19`（与 Android 版一致）。
- **本次功能**：
  1. **大屏侧边导航**（`home_screen.dart`）：窗口宽度 ≥720dp 时底部 `NavigationBar` 改为左侧 `NavigationRail`（默认窗口 1280×720 即触发），与平板 APK 同一代码。
  2. **应用内更新下载修复**（`settings_screen.dart` + `update_service.dart`）：下载与进度对话框并行启动（旧逻辑下载从未开始，恒 0%）；下载客户端独立化（浏览器 UA）+ 短超时重试，Windows 端 `.exe` 安装器下载更稳。
- **构建**：push 到 `feature/windows-support` 自动触发 `build-windows` workflow（run 34682802415），约 **5m** 成功。
- **安装器**：`stdeel-setup-0.7.2.exe`，20.4MB。
- **发布**：`gh release upload v0.7.2 stdeel-setup-0.7.2.exe`（与 `app-0.7.2.apk` 同一 Pre-Release）。
  - 链接：https://github.com/IFFCheckPass/STDeel/releases/tag/v0.7.2
- **收尾**：删除本地下载副本，保持工作区干净。
