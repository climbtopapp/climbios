import SwiftUI

/// Toast notification overlay matching the web app's toast system
struct ToastView: View {
    let message: String
    let type: AppState.ToastType

    var backgroundColor: Color {
        switch type {
        case .success: return ClimbTheme.successColor
        case .error: return ClimbTheme.errorColor
        case .info: return ClimbTheme.bgSecondary
        }
    }

    var textColor: Color {
        switch type {
        case .success: return .black
        case .error: return .white
        case .info: return ClimbTheme.textMain
        }
    }

    var body: some View {
        Text(message)
            .font(ClimbTheme.bodyFont(size: 14))
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// Brutalist text field matching the web app's input styling
struct BrutalistTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var hint: String? = nil
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var disabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.primaryColor)
                .textCase(.uppercase)
                .tracking(1)

            TextField(placeholder, text: $text)
                .font(ClimbTheme.bodyFont(size: 16))
                .foregroundColor(disabled ? ClimbTheme.textMuted : ClimbTheme.textMain)
                .padding(12)
                .background(disabled ? ClimbTheme.bgSecondary : ClimbTheme.bgPrimary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .disabled(disabled)

            if let hint = hint {
                Text(hint)
                    .font(ClimbTheme.bodyFont(size: 12))
                    .foregroundColor(ClimbTheme.textMuted)
            }
        }
    }
}

/// Mash-style selection card component
struct MashSelectionCard: View {
    let title: String
    let icon: AnyView
    let isSelected: Bool
    var rotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Icon area
            ZStack {
                Rectangle()
                    .fill(isSelected ? ClimbTheme.primaryColor : ClimbTheme.bgSecondary)
                    .frame(height: 100)

                icon
                    .foregroundColor(isSelected ? .black : ClimbTheme.accentColor)
            }

            // Divider
            Rectangle()
                .fill(ClimbTheme.borderColor)
                .frame(height: ClimbTheme.borderWidth)

            // Label area
            HStack {
                Spacer()
                Text(title)
                    .font(ClimbTheme.bodyFont(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? ClimbTheme.primaryColor : .black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.black : ClimbTheme.primaryColor)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: 2)
                    )
                Spacer()
            }
            .padding(.vertical, 12)
            .background(isSelected ? ClimbTheme.primaryLight : ClimbTheme.bgSecondary)
        }
        .frame(maxWidth: 170)
        .overlay(
            Rectangle()
                .stroke(isSelected ? ClimbTheme.accentColor : ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
        .rotationEffect(.degrees(rotation))
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

/// "or" divider matching the web's mash-vs element
struct OrDivider: View {
    var body: some View {
        Text("or")
            .font(ClimbTheme.displayFont(size: 28))
            .foregroundColor(.white)
            .textCase(.uppercase)
            .tracking(1)
            .frame(width: 44, height: 44)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
    }
}

/// Rank row component for leaderboard lists
struct RankRow: View {
    let rank: String
    let name: String
    let location: String
    let avatarUrl: String?
    var isTopThree: Bool = false
    var rankIndex: Int = 99

    private var badgeBackground: Color {
        switch rankIndex {
        case 0: return ClimbTheme.primaryColor
        case 1: return ClimbTheme.accentColor
        case 2: return ClimbTheme.bgSecondary
        default: return ClimbTheme.bgPrimary
        }
    }

    private var avatarBorderColor: Color {
        rankIndex < 3 ? ClimbTheme.primaryColor : ClimbTheme.borderColor
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text(rank)
                .font(ClimbTheme.displayFont(size: 22))
                .frame(width: 32, height: 28)
                .background(badgeBackground)
                .foregroundColor(rankIndex < 3 ? .black : ClimbTheme.textMuted)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )

            // Avatar
            AsyncImage(url: URL(string: avatarUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(ClimbTheme.bgPrimary)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(ClimbTheme.accentColor)
                        )
                default:
                    Rectangle()
                        .fill(ClimbTheme.bgPrimary)
                        .overlay(ProgressView())
                }
            }
            .frame(width: 44, height: 44)
            .clipped()
            .overlay(
                Rectangle()
                    .stroke(avatarBorderColor, lineWidth: 2)
            )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(ClimbTheme.bodyFont(size: 15))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.textMain)
                    .lineLimit(1)

                Text(location)
                    .font(ClimbTheme.bodyFont(size: 12))
                    .foregroundColor(ClimbTheme.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }
}

/// Tab selector matching the web's .tabs element
struct BrutalistTabs: View {
    let tabs: [String]
    @Binding var selectedTab: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab)
                        .font(ClimbTheme.bodyFont(size: 14))
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(selectedTab == tab ? .black : ClimbTheme.textMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? ClimbTheme.primaryColor : Color.clear)
                        .overlay(
                            Group {
                                if selectedTab == tab {
                                    Rectangle()
                                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }
}

/// Gender filter sub-tabs
struct GenderFilterTabs: View {
    let options: [(label: String, value: String)]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.value) { option in
                Button(action: { selected = option.value }) {
                    Text(option.label)
                        .font(ClimbTheme.displayFont(size: 13))
                        .fontWeight(.bold)
                        .foregroundColor(selected == option.value ? ClimbTheme.textMain : ClimbTheme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(selected == option.value ? ClimbTheme.bgSecondary : ClimbTheme.bgPrimary)
                        .overlay(
                            Rectangle()
                                .stroke(ClimbTheme.borderColor, lineWidth: 2)
                        )
                }
            }
        }
    }
}
