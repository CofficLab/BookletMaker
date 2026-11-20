# BookletMaker

> **BookletMaker** 是一款跨平台 PDF 小册子制作与文档工具应用。
> 支持小册子拼版、PDF 合并/拆分、页面检查等功能，覆盖 macOS、iOS 和 visionOS。

📖 中文 | [English](README.md)

## 功能

- **小册子模式** — 将 PDF 页面按小册子拼版排列，用于双面打印和装订
- **PDF 合并** — 将多个 PDF 文档合并为一个
- **PDF 拆分** — 按页码范围拆分 PDF 文档
- **PDF 检查器** — 查看页面尺寸、旋转角度和元数据
- **主题支持** — 多种内置主题，实时切换
- **通用购买** — 一次购买覆盖 macOS、iOS 和 visionOS

## 平台要求

| 平台 | 最低版本 |
|------|---------|
| macOS | 14.0+ |
| iOS / iPadOS | 17.0+ |
| visionOS | 2.0+ |

## 架构

BookletMaker 使用 [LumiFactory](https://github.com/lumi-softworks/LumiFactory) 装配框架：

- **`BookletMakerManifest.swift`** — 组合根：`HostManifest` 声明品牌标识、插件目录、存储/主题兼容性和平台窗口壳工厂。
- **`BookletMakerApp.swift`**（`@main`）— 仅负责平台分发。macOS 上，`@NSApplicationDelegateAdaptor(HostAppDelegate)` 和 `HostAppDelegate.prepareForLaunch()` 挂在 `@main` 根 App 上。
- **`BookletMakerAssembly`** — 宿主级单例，持有主窗口和设置窗口共享的 `KernelBootstrapper`。

业务逻辑位于远程插件包 [LumiPluginBookletMaker](https://github.com/lumi-softworks/LumiPluginBookletMaker)。

## 依赖

所有依赖均为远程 Swift 包：

| 包 | 版本 | 用途 |
|----|------|------|
| [LumiFactory](https://github.com/lumi-softworks/LumiFactory) | 1.7.x | App 装配引擎 |
| [LumiKernel](https://github.com/lumi-softworks/LumiKernel) | 1.1.x | 插件内核 |
| [LumiUI](https://github.com/lumi-softworks/LumiUI) | 1.18.x | 共享 UI 组件 |
| [LumiProviders](https://github.com/lumi-softworks/LumiProviders) | 1.26.x | Provider 协议与默认实现 |
| [LumiPluginBookletMaker](https://github.com/lumi-softworks/LumiPluginBookletMaker) | 2.2.x | 核心小册子业务逻辑 |
| [LumiPluginThemePack](https://github.com/lumi-softworks/LumiPluginThemePack) | 1.2.x | 主题管理 |
| [LumiPluginSettingGeneral](https://github.com/lumi-softworks/LumiPluginSettingGeneral) | 1.3.x | 通用设置页 |
| [LumiPluginAbout](https://github.com/lumi-softworks/LumiPluginAbout) | 3.0.x | 关于页 |
| [LumiPluginPluginManager](https://github.com/lumi-softworks/LumiPluginPluginManager) | 1.7.x | 插件生命周期 |

## 构建

```bash
# 在 Xcode 中打开
open BookletMaker.xcodeproj

# 或从命令行构建（macOS）
xcodebuild -project BookletMaker.xcodeproj -scheme BookletMaker -configuration Release build
```

## 历史

BookletMaker 最初是 [GameFactory](https://github.com/CofficLab/GameFactory) 多 App 宿主工程的一部分。现已提取为独立项目，用于独立开发和分发。

## 许可证

[GNU General Public License v3.0](LICENSE)
