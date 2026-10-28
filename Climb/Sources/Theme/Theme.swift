import SwiftUI

/// Design tokens matching the web app's CSS variables
/// Neo-brutalist style: no border radius, black borders, pastel blue accents
struct ClimbTheme {
    // Dynamic color helper for Light & Dark mode support
    private static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    // Colors supporting dynamic Light & Dark mode
    static let bgPrimary = dynamicColor(
        light: UIColor(red: 0.922, green: 0.945, blue: 0.980, alpha: 1.0), // #ebf1fa
        dark: UIColor(red: 0.055, green: 0.071, blue: 0.090, alpha: 1.0)  // #0e1217
    )
    static let bgSecondary = dynamicColor(
        light: UIColor.white,
        dark: UIColor(red: 0.086, green: 0.106, blue: 0.133, alpha: 1.0)  // #161b22
    )
    static let primaryColor = dynamicColor(
        light: UIColor(red: 0.733, green: 0.871, blue: 0.984, alpha: 1.0), // #bbdefb
        dark: UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1.0)   // #3b82f6
    )
    static let primaryHover = dynamicColor(
        light: UIColor(red: 0.565, green: 0.792, blue: 0.976, alpha: 1.0), // #90caf9
        dark: UIColor(red: 0.145, green: 0.388, blue: 0.922, alpha: 1.0)   // #2563eb
    )
    static let primaryLight = dynamicColor(
        light: UIColor(red: 0.890, green: 0.949, blue: 0.992, alpha: 1.0), // #e3f2fd
        dark: UIColor(red: 0.118, green: 0.161, blue: 0.231, alpha: 1.0)   // #1e293b
    )
    static let textMain = dynamicColor(
        light: UIColor.black,
        dark: UIColor(red: 0.941, green: 0.965, blue: 0.988, alpha: 1.0)   // #f0f6fc
    )
    static let textMuted = dynamicColor(
        light: UIColor(red: 0.333, green: 0.333, blue: 0.400, alpha: 1.0), // #555566
        dark: UIColor(red: 0.545, green: 0.580, blue: 0.620, alpha: 1.0)   // #8b949e
    )
    static let borderColor = dynamicColor(
        light: UIColor.black,
        dark: UIColor(red: 0.216, green: 0.255, blue: 0.318, alpha: 1.0)   // #374151
    )
    static let accentColor = dynamicColor(
        light: UIColor(red: 0.259, green: 0.647, blue: 0.961, alpha: 1.0), // #42a5f5
        dark: UIColor(red: 0.376, green: 0.647, blue: 0.980, alpha: 1.0)   // #60a5fa
    )
    static let primaryButtonText = dynamicColor(
        light: UIColor.black,
        dark: UIColor.white
    )
    static let successColor = Color(red: 0, green: 0.784, blue: 0.325) // #00c853
    static let errorColor = Color(red: 1, green: 0.231, blue: 0.188)   // #ff3b30

    // Border width
    static let borderWidth: CGFloat = 3

    // Font names
    static let fontLogo = "VT323-Regular"
    static let fontDisplay = "Sen-Bold"
    static let fontBody = "Sen-Regular"

    // Fallback system fonts
    static func logoFont(size: CGFloat) -> Font {
        if let _ = UIFont(name: fontLogo, size: size) {
            return .custom(fontLogo, size: size)
        }
        return .system(size: size, weight: .regular, design: .monospaced)
    }

    static func displayFont(size: CGFloat) -> Font {
        if let _ = UIFont(name: fontDisplay, size: size) {
            return .custom(fontDisplay, size: size)
        }
        return .system(size: size, weight: .bold, design: .default)
    }

    static func bodyFont(size: CGFloat) -> Font {
        if let _ = UIFont(name: fontBody, size: size) {
            return .custom(fontBody, size: size)
        }
        return .system(size: size, weight: .regular, design: .default)
    }
}

// MARK: - View Modifiers

struct BrutalistCardModifier: ViewModifier {
    var padding: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ClimbTheme.bgSecondary)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
    }
}

extension View {
    func brutalistCard(padding: CGFloat = 24) -> some View {
        modifier(BrutalistCardModifier(padding: padding))
    }
}

// MARK: - Button Styles

struct BrutalistPrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClimbTheme.bodyFont(size: 16))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(ClimbTheme.primaryColor)
            .foregroundColor(ClimbTheme.primaryButtonText)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BrutalistSecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClimbTheme.bodyFont(size: 16))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(ClimbTheme.bgSecondary)
            .foregroundColor(ClimbTheme.textMain)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BrutalistTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClimbTheme.bodyFont(size: 16))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .foregroundColor(ClimbTheme.textMuted)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

struct BrutalistSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClimbTheme.bodyFont(size: 14))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(ClimbTheme.bgSecondary)
            .foregroundColor(ClimbTheme.textMain)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BrutalistDestructiveButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClimbTheme.bodyFont(size: 16))
            .fontWeight(.bold)
            .textCase(.uppercase)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(ClimbTheme.errorColor)
            .foregroundColor(.white)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
