import SwiftUI

/// Mirrors the Android Material 3 theme
/// (android/app/src/main/java/com/example/scanner/theme).
enum ScannerTheme {

    /// Static palette (the accent tint itself comes from AccentColor in Assets.xcassets).
    enum Palette {
        static let purple40 = Color(red: 0x66 / 255, green: 0x50 / 255, blue: 0xa4 / 255)
        static let purple80 = Color(red: 0xd0 / 255, green: 0xbc / 255, blue: 0xff / 255)
    }

    /// Text styles mirroring Material 3 typography.
    enum Typography {
        static let headline = Font.system(.largeTitle, design: .default, weight: .bold)
        static let body = Font.body
        static let label = Font.caption.bold()
    }
}
