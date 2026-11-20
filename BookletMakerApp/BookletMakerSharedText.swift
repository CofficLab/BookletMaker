import Foundation

/// 宿主共享文案（macOS / iOS / visionOS 共用 App bundle 的同一份 catalog）。
enum BookletMakerSharedText {
    static func string(_ key: String, locale: Locale = .current) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main, locale: locale)
    }
}