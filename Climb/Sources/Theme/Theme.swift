import SwiftUI

/// Design tokens matching the web app's CSS variables
/// Neo-brutalist style: no border radius, black borders, pastel blue accents
struct ClimbTheme {
    // Colors
    static let bgPrimary = Color(red: 0.922, green: 0.945, blue: 0.980) // #ebf1fa
    static let bgSecondary = Color.white // #ffffff
    static let primaryColor = Color(red: 0.733, green: 0.871, blue: 0.984) // #bbdefb
    static let primaryHover = Color(red: 0.565, green: 0.792, blue: 0.976) // #90caf9
    static let primaryLight = Color(red: 0.890, green: 0.949, blue: 0.992) // #e3f2fd
    static let textMain = Color.black // #000000
    static let textMuted = Color(red: 0.333, green: 0.333, blue: 0.400) // #555566
    static let borderColor = Color.black // #000000
    static let accentColor = Color(red: 0.259, green: 0.647, blue: 0.961) // #42a5f5
    static let successColor = Color(red: 0, green: 0.784, blue: 0.325) // #00c853
    static let errorColor = Color(red: 1, green: 0.231, blue: 0.188) // #ff3b30

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
            .foregroundColor(.black)
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
