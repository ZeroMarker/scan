# ADB 无线调试指南

## 前置条件

- Android 设备已启用 USB 调试（开发者选项）
- 设备与电脑在同一 Wi-Fi 网络
- 已安装 Android SDK Platform-Tools

## ADB 路径

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

## 无线调试设置

### 方法一：USB 转无线（传统方法）

**原理：** 通过 `adb tcpip` 命令让设备的 adbd 守护进程在指定端口上监听 TCP 连接，无需在设备上开启"无线调试"选项。

```powershell
# 1. USB 连接设备后，查看已连接设备
& $adb devices

# 2. 获取设备 Wi-Fi IP 地址
& $adb shell ip route

# 3. 启用 TCP/IP 模式（端口 5555）
& $adb tcpip 5555

# 4. 通过 Wi-Fi 连接设备
& $adb connect <设备IP>:5555

# 5. 拔掉 USB 线，验证连接
& $adb devices
```

**特点：**
- 不需要在设备上开启"无线调试"
- 每次设备重启后需要重新用 USB 执行 `adb tcpip 5555`
- 兼容所有 Android 版本

### 方法二：Android 11+ 无线配对（新方法）

**原理：** Android 11 引入的原生无线调试功能，通过配对码验证身份，支持重启后自动连接。

```powershell
# 1. 在设备上：设置 > 开发者选项 > 无线调试 > 启用

# 2. 点击"使用配对码配对设备"，获取配对码和端口

# 3. 配对设备
& $adb pair <设备IP>:<配对端口> <配对码>

# 4. 连接设备（使用无线调试页面显示的端口）
& $adb connect <设备IP>:<连接端口>
```

**特点：**
- 需要 Android 11+
- 首次配对后重启仍可连接
- 无需 USB 线

### 两种方法对比

| 特性 | USB 转无线 | Android 11+ 无线配对 |
|------|-----------|---------------------|
| Android 版本要求 | 无 | Android 11+ |
| 是否需要 USB | 首次需要 | 完全不需要 |
| 设备重启后 | 需重新用 USB 设置 | 自动连接 |
| 安全性 | 较低 | 配对码验证 |
| 稳定性 | 高 | 高 |

## 常用命令

### 设备管理

```powershell
# 列出已连接设备
& $adb devices

# 断开设备
& $adb disconnect <设备IP>:5555

# 断开所有设备
& $adb disconnect
```

### APK 安装与卸载

```powershell
# 指定设备安装（IP:端口 方式）
& $adb -s <设备IP>:5555 install app-debug.apk

# 指定设备安装（TLS 设备名称方式，Android 11+ 无线调试）
& $adb -s <TLS设备名称> install app-debug.apk

# 覆盖安装（保留数据）
& $adb -s <设备标识> install -r app-debug.apk

# 卸载应用
& $adb -s <设备标识> uninstall com.example.app
```

**设备标识说明：**
- `IP:端口` - 通过 `adb tcpip` 或 `adb connect` 连接的设备
- `TLS设备名称` - Android 11+ 无线调试自动连接的设备，格式为 `adb-<序列号>-...`
- `序列号` - USB 直连的设备

**获取设备标识：**
```powershell
# 查看所有已连接设备及其标识
& $adb devices
```

### 应用管理

```powershell
# 启动应用
& $adb -s <设备IP>:5555 shell am start -n com.example.app/.MainActivity

# 强制停止应用
& $adb -s <设备IP>:5555 shell am force-stop com.example.app

# 清除应用数据
& $adb -s <设备IP>:5555 shell pm clear com.example.app
```

### 文件传输

```powershell
# 推送文件到设备
& $adb -s <设备IP>:5555 push local.txt /sdcard/

# 从设备拉取文件
& $adb -s <设备IP>:5555 pull /sdcard/file.txt ./
```

### 日志查看

```powershell
# 查看设备日志
& $adb -s <设备IP>:5555 logcat

# 过滤特定应用日志
& $adb -s <设备IP>:5555 logcat --pid=$(adb shell pidof com.example.app)

# 清除日志
& $adb -s <设备IP>:5555 logcat -c
```

### 截图与录屏

```powershell
# 截图
& $adb -s <设备IP>:5555 shell screencap /sdcard/screenshot.png
& $adb -s <设备IP>:5555 pull /sdcard/screenshot.png ./

# 录屏（Ctrl+C 停止）
& $adb -s <设备IP>:5555 shell screenrecord /sdcard/video.mp4
```

## 快速连接命令

```powershell
# 连接当前项目设备
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" connect 10.72.123.90:5555
```
