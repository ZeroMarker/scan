# Scanner (iOS)

条码 / 二维码扫描应用（iOS 端），SwiftUI + AVFoundation，功能与 Android 端对齐。

> 对应 Android 实现见 [`android/`](../android/README.md)。

## 功能

- 实时扫描条码和二维码（QR、Code 128 / 39 / 93、Codabar、Data Matrix、EAN-13 / 8、ITF、UPC-E、PDF417、Aztec）
- 相机权限申请，拒绝后引导跳转系统设置
- 扫描结果展示（条码类型 + 内容，支持长按选中文本）
- 一键复制结果到剪贴板（UIPasteboard）
- 再次扫描 / 返回主页
- 深色模式自动适配（系统颜色方案）

## 与 Android 的差异（平台特性）

| 项目 | Android | iOS |
|---|---|---|
| UI | Jetpack Compose (Material 3) | SwiftUI |
| 扫描引擎 | ML Kit Barcode Scanning | AVFoundation `AVCaptureMetadataOutput` |
| 条码类型 | 13 种 | 12 种（UPC-A 由 iOS 以 EAN-13 上报，无独立类型） |
| 架构 | ViewModel + StateFlow | `@MainActor` ViewModel + `@Published` |
| 导航 | Navigation3 | `NavigationStack` + `navigationDestination` |

## 环境要求

- Xcode 16+（工程使用 `PBXFileSystemSynchronizedRootGroup` 同步文件夹格式）
- iOS 17.0+ 部署目标

## 构建与测试

```bash
# 打开工程（或双击 Scanner.xcodeproj）
open Scanner.xcodeproj

# 命令行构建
xcodebuild -project Scanner.xcodeproj -scheme Scanner -destination 'generic/platform=iOS Simulator' build

# 单元测试（ScannerTests）
xcodebuild test -project Scanner.xcodeproj -scheme Scanner -destination 'platform=iOS Simulator,name=iPhone 16'

# UI 测试（ScannerUITests）
xcodebuild test -project Scanner.xcodeproj -scheme Scanner \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ScannerUITests
```

> 首次在真机运行时需要在 Signing & Capabilities 中选择开发团队。

## CI

仓库已配置 [iOS 工作流](../.github/workflows/ios.yml)：`ios/**` 变更时在 macOS runner 上执行模拟器构建、单元测试与 UI 测试。

## 目录结构

```
Scanner.xcodeproj/          # Xcode 工程（同步文件夹，自动收录新文件）
Scanner/
├── ScannerApp.swift        # 入口（@main）
├── Navigation/MainRouter.swift   # 导航（≈ Android Navigation.kt）
├── Data/DataRepository.swift     # 数据层占位（≈ Android DataRepository.kt）
├── Theme/ScannerTheme.swift      # 主题（≈ Android theme/）
├── UI/Main/                       # 主屏幕 + ViewModel
└── UI/Scanner/                    # 扫描屏 + BarcodeAnalyzer + CameraPreview
ScannerTests/               # 单元测试（≈ android app/src/test）
ScannerUITests/             # UI 测试（≈ android app/src/androidTest）
```

## 权限说明

相机权限声明在工程设置的 `INFOPLIST_KEY_NSCameraUsageDescription` 中；
运行时权限流程与 Android 版一致（首次请求 → 拒绝后显示说明 + 跳转系统设置）。
