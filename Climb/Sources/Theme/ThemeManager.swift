import SwiftUI

/// Manages app theme & appearance mode
/// Supports:
/// 1. Auto Switch that automatically reacts to iOS system dark/light mode
/// 2. Manual Dark Mode toggle (when Auto Switch is disabled)
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("climb_appearance_auto") var autoMatchSystem: Bool = true {
        willSet {
            objectWillChange.send()
        }
    }

    @AppStorage("climb_appearance_dark") var isDarkMode: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }

    /// ColorScheme passed to .preferredColorScheme()
    /// - nil: automatically follows system appearance in real-time
    /// - .dark: explicitly forced dark mode
    /// - .light: explicitly forced light mode
    var preferredColorScheme: ColorScheme? {
        if autoMatchSystem {
            return nil
        }
        return isDarkMode ? .dark : .light
    }
}
