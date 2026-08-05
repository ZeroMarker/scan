# Scanner

[![Android CI](https://github.com/ZeroMarker/scan/actions/workflows/android-ci.yml/badge.svg)](https://github.com/ZeroMarker/scan/actions/workflows/android-ci.yml)
[![iOS](https://github.com/ZeroMarker/scan/actions/workflows/ios.yml/badge.svg)](https://github.com/ZeroMarker/scan/actions/workflows/ios.yml)

跨平台条码 / 二维码扫描应用：**Android**（Kotlin + Jetpack Compose + CameraX + ML Kit）与 **iOS**（SwiftUI + AVFoundation）双端实现，功能与 UI 对齐。

## 目录结构

```
├── android/          # Android 应用（Gradle 工程）
├── ios/              # iOS 应用（Xcode 工程，Xcode 16+）
├── CHANGELOG.md      # 变更记录
└── LICENSE
```

## 功能

- 实时扫描条码和二维码（QR、Code 128/39/93、EAN-13/8、UPC-A/E、Data Matrix、PDF417、Aztec、ITF、Codabar）
- 相机权限申请与拒绝引导（支持跳转系统设置）
- 扫描结果展示（条码类型 + 内容）
- 一键复制到剪贴板、再次扫描、返回主页
- 深色模式自动适配

## 快速开始

| 平台 | 说明 |
|---|---|
| Android | 进入 [`android/`](android/README.md)，`./gradlew assembleDebug` |
| iOS | 进入 [`ios/`](ios/README.md)，Xcode 16+ 打开 `Scanner.xcodeproj` |

## 架构对应

| Android | iOS |
|---|---|
| MainActivity + Navigation3 | `@main` App + `NavigationStack` |
| MainScreenViewModel (StateFlow) | `@MainActor` ViewModel (`@Published`) |
| ML Kit BarcodeAnalyzer | AVFoundation `AVCaptureMetadataOutput` |
| CameraX PreviewView | `UIViewRepresentable` 预览层 |
| 单元测试 / 仪器测试 | XCTest / XCUITest |

## CI

| 工作流 | 触发 | 内容 |
|---|---|---|
| [Android CI](.github/workflows/android-ci.yml) | push/PR（`android/**` 变更） | 单元测试 + 构建 debug APK |
| [iOS](.github/workflows/ios.yml) | push/PR（`ios/**` 变更） | 模拟器构建 + 单元测试 + UI 测试 |
| [Release](.github/workflows/release.yml) | 打 tag（`v*`） | 构建并发布 Android APK（debug + release） |
