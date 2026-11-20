#if os(visionOS)
import KernelCore
import LumiFactory
import ProviderContentView
import ProviderRailView
import ProviderSettingView
import ProviderTheme
import SwiftUI

/// visionOS 应用入口：自有窗口壳（标题栏齿轮 + 侧栏 + 内容区 + 设置 sheet）。
///
/// visionOS 的窗口是空间中的一块平面，默认尺寸按双栏（侧栏 + 内容区）比例给出；
/// 用户仍可自由缩放。装配由共享引导器完成，这里只保留窗口壳布局。
struct BookletMakerVisionApp: App {
    var body: some Scene {
        WindowGroup {
            BookletMakerVisionRootView(bootstrapper: BookletMakerAssembly.bootstrapper)
        }
        .defaultSize(width: 1280, height: 800)
    }
}

/// 三态驱动窗口壳：加载 / 失败 / 就绪。
@MainActor
private struct BookletMakerVisionRootView: View {
    @ObservedObject var bootstrapper: KernelBootstrapper

    var body: some View {
        switch bootstrapper.state {
        case .idle, .booting:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await bootstrapper.boot() }
        case .failed(let report):
            ContentUnavailableView(
                BookletMakerSharedText.string("Booklet Maker unavailable"),
                systemImage: "exclamationmark.triangle",
                description: Text(report.technicalDetail)
            )
        case .ready(let kernel):
            BookletMakerVisionWorkspace(kernel: kernel)
                .id(ObjectIdentifier(kernel))
        }
    }
}

/// 就绪后的工作台：标题栏 + 侧栏 + 内容区，主题随选择实时桥接。
@MainActor
private struct BookletMakerVisionWorkspace: View {
    let kernel: KernelCoreContainer
    @State private var isShowingSettings = false

    var body: some View {
        let workspace = VStack(spacing: 0) {
            header
            Divider()
            HStack(spacing: 0) {
                if let rail {
                    rail
                        .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
                    Divider()
                }
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        Group {
            if let theme {
                HostThemeView(theme: theme, content: workspace)
            } else {
                workspace
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $isShowingSettings) {
            settingsSheet
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("BookletMaker")
                .font(.headline)
            Spacer()
            if settings != nil {
                Button {
                    isShowingSettings = true
                } label: {
                    Label(
                        BookletMakerSharedText.string("Settings"),
                        systemImage: "gearshape"
                    )
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(BookletMakerSharedText.string("Settings"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var settingsSheet: some View {
        Group {
            if let settings {
                if let theme {
                    HostThemeView(theme: theme, content: settings)
                } else {
                    settings
                }
            } else {
                ContentUnavailableView(
                    BookletMakerSharedText.string("Settings unavailable"),
                    systemImage: "gearshape"
                )
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Kernel Reads

    private var theme: (any ThemeProviding)? {
        kernel.resolveProvider((any ThemeProviding).self)
    }

    private var content: AnyView {
        kernel.resolveProvider((any ContentViewProviding).self)?.makeContentView()
            ?? AnyView(Text(BookletMakerSharedText.string("Booklet Maker unavailable")))
    }

    private var rail: AnyView? {
        kernel.resolveProvider((any RailViewProviding).self).map { AnyView($0.makeRailView()) }
    }

    private var settings: AnyView? {
        kernel.resolveProvider((any SettingViewProviding).self).map { $0.makeSettingView() }
    }
}
#endif