# BookletMaker

> **BookletMaker** is a cross-platform PDF booklet creation and document utility app.
> It supports booklet imposition, PDF merging/splitting, and page inspection on macOS, iOS, and visionOS.

📖 [中文版](README_zh.md) | English

## Features

- **Booklet Mode** — Arrange PDF pages into booklet-imposed sheets for double-sided printing and binding
- **PDF Merge** — Combine multiple PDF documents into one
- **PDF Split** — Split PDF documents by page ranges
- **PDF Inspector** — View page dimensions, rotation, and metadata
- **Theme Support** — Multiple built-in themes with real-time switching
- **Universal Purchase** — One purchase covers macOS, iOS, and visionOS

## Platforms

| Platform | Minimum Version |
|----------|----------------|
| macOS | 14.0+ |
| iOS / iPadOS | 17.0+ |
| visionOS | 2.0+ |

## Architecture

BookletMaker uses the [LumiFactory](https://github.com/lumi-softworks/LumiFactory) assembly framework:

- **`BookletMakerManifest.swift`** — The composition root: a `HostManifest` declaring brand identity, plugin catalog, storage/theme compatibility, and platform shell factories.
- **`BookletMakerApp.swift`** (`@main`) — Platform dispatch only. On macOS, the `@NSApplicationDelegateAdaptor(HostAppDelegate)` and `HostAppDelegate.prepareForLaunch()` live on the `@main` root App.
- **`BookletMakerAssembly`** — Host-level singleton holding the one `KernelBootstrapper` shared by the main and settings windows.

Business logic lives in the remote plugin package [LumiPluginBookletMaker](https://github.com/lumi-softworks/LumiPluginBookletMaker).

## Dependencies

All dependencies are remote Swift packages:

| Package | Version | Purpose |
|---------|---------|---------|
| [LumiFactory](https://github.com/lumi-softworks/LumiFactory) | 1.7.x | App assembly engine |
| [LumiKernel](https://github.com/lumi-softworks/LumiKernel) | 1.1.x | Plugin kernel |
| [LumiUI](https://github.com/lumi-softworks/LumiUI) | 1.18.x | Shared UI components |
| [LumiProviders](https://github.com/lumi-softworks/LumiProviders) | 1.26.x | Provider protocols & defaults |
| [LumiPluginBookletMaker](https://github.com/lumi-softworks/LumiPluginBookletMaker) | 2.2.x | Core booklet business logic |
| [LumiPluginThemePack](https://github.com/lumi-softworks/LumiPluginThemePack) | 1.2.x | Theme management |
| [LumiPluginSettingGeneral](https://github.com/lumi-softworks/LumiPluginSettingGeneral) | 1.3.x | General settings page |
| [LumiPluginAbout](https://github.com/lumi-softworks/LumiPluginAbout) | 3.0.x | About page |
| [LumiPluginPluginManager](https://github.com/lumi-softworks/LumiPluginPluginManager) | 1.7.x | Plugin lifecycle |

## Build

```bash
# Open in Xcode
open BookletMaker.xcodeproj

# Or build from command line (macOS)
xcodebuild -project BookletMaker.xcodeproj -scheme BookletMaker -configuration Release build
```

## History

BookletMaker was originally part of the [GameFactory](https://github.com/CofficLab/GameFactory) multi-app host project. It has been extracted as a standalone project for independent development and distribution.

## License

[GNU General Public License v3.0](LICENSE)
