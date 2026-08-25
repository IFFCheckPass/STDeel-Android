# BUILD.md — 思谛 STDeel 编译 / 打包 / 发布记录与指南

> 本文件由 AGENTS.md 规则驱动：**每次成功编译后，将一整套环境准备与编译过程
> （工具链/依赖/签名/构建/上传命令）写入本文，以备下次使用**，并随仓库同步 `main`。
> 最新一次成功的构建过程见底部「累计记录」。

## 一、环境准备（首次一次性）

### 1.1 Flutter SDK
- 本仓库 `.metadata` 记录的 Flutter revision：`4cf24164269a5ebf0c16a028a00727d0e77bbb05`（stable）。
- `pubspec.yaml` 要求 `flutter >= 3.35.0`，Dart SDK `>=3.5.0 <4.0.0`。
- 安装（无 Flutter 时）：
  ```bash
  cd /opt
  curl -L -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.1-stable.tar.xz
  tar -xf flutter.tar.xz -C /opt
  export PATH="/opt/flutter/bin:$PATH"
  flutter config --no-analytics
  ```

### 1.2 Android SDK
- `ANDROID_HOME=/opt/android`。
- 安装 cmdline-tools 后用 `sdkmanager` 安装：`platform-tools`、`platforms;android-<compileSdk>`、`build-tools;36.0.0`、所需 NDK。
- 接受许可：`yes | sdkmanager --licenses`。

### 1.3 Java / Gradle
- 本项目要求 JDK 17（`android/gradle.properties` 已固定 `org.gradle.java.home=.../java/17.0.2`）。
- Gradle 8.x（本机 8.14.5）。

### 1.4 网络（受限容器）
- 通过代理 `http://127.0.0.1:18080`（环境变量 `HTTP(S)_PROXY`；`android/gradle.properties` 也配置了 systemProp 代理）。
- 注意：`storage.googleapis.com` 大文件下载可能很慢（受容器限速）；如中断可用 `curl -C -` 续传。

## 二、构建与发布流程

```bash
scripts/build-release.sh              # 一键：环境→签名→构建→上传→回写本文
```

等价手动步骤：
```bash
# 1) 取签名文件（仅构建用，不并入 main）
git checkout feature/signing-config -- android/upload-keystore.jks android/key.properties

# 2) 在 android/app/build.gradle.kts 的 buildTypes.release 临时启用签名并构建
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter build apk --release

# 3) 产物改名为 app-<版本号>.apk 并上传
cp build/app/outputs/flutter-apk/app-release.apk app-<版本号>.apk
# 版本 >=1.0.0 且为 a.b.0 → Release；否则 Pre-Release
gh release create v<版本号> [--prerelease] --repo IFFCheckPass/STDeel-Android app-<版本号>.apk

# 4) 清理签名文件并恢复 build.gradle.kts，保持 main 干净
rm -f android/upload-keystore.jks android/key.properties
```

## 三、累计记录

### v0.5.1（本次，待成功构建后补全）
- 环境：Flutter SDK 需重新安装（本沙箱无预装工具链，storage.googleapis 限速 ~30-150KB/s）。
- 状态：代码已推送 main，工具链安装受限于网络下载速度，构建待完成。
- 成功后在此追加：实际安装命令、耗时、产物 sha、tag/Release 链接。