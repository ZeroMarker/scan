# Scanner (Android)

条码 / 二维码扫描应用（Android 端），Kotlin + Jetpack Compose + CameraX + ML Kit。

> 对应 iOS 实现见 [`../ios/README.md`](../ios/README.md)。

## 功能

- 实时扫描条码和二维码（Code 128 / 39 / 93、EAN-13 / 8、UPC-A / E、QR Code、Data Matrix、PDF417、Aztec、ITF、Codabar）
- 相机权限申请，拒绝后引导跳转系统设置
- 扫描结果展示（条码类型 + 内容）
- 一键复制结果到剪贴板
- 再次扫描 / 返回主页
- 深色模式与 Android 12+ 动态取色

## 技术栈

- Kotlin 2.3 + AGP 9.0，Jetpack Compose（Material 3）
- CameraX 1.5（预览 + 图像分析）
- ML Kit Barcode Scanning 17.3
- Navigation3 + kotlinx.serialization
- MVVM 架构（ViewModel + StateFlow）

## 构建与测试

```bash
./gradlew assembleDebug          # 构建 debug APK
./gradlew testDebugUnitTest      # 单元测试
./gradlew connectedAndroidTest   # 仪器测试（需要设备/模拟器）
```

## 目录结构

```
app/src/main/java/com/example/scanner/
├── MainActivity.kt          # 入口 Activity
├── Navigation.kt            # Navigation3 导航
├── NavigationKeys.kt        # 导航目的地定义
├── data/                    # 数据层（Repository）
├── theme/                   # Material3 主题
└── ui/
    ├── main/                # 主屏幕 + ViewModel
    └── scanner/             # 扫描屏幕 + ML Kit 分析器
```

## 真机调试

无线调试（ADB）步骤见 [adb.md](adb.md)。
