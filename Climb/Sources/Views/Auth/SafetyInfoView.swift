import SwiftUI

/// Safety Information modal — matches the web's safety-modal
struct SafetyInfoView: View {
    @Environment(\.dismiss) var dismiss

    struct SafetyItem: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let description: String
    }

    let items: [SafetyItem] = [
        SafetyItem(
            icon: "magnifyingglass",
            iconColor: ClimbTheme.errorColor,
            title: "No Search",
            description: "There is no search bar, so nobody can look up specific users to target or stalk."
        ),
        SafetyItem(
            icon: "heart.fill",
            iconColor: Color(red: 1, green: 0.231, blue: 0.188),
            title: "Positive Vibes Only",
            description: "We only show top-voted profiles. There is no \"bottom\" list, and nobody gets publicly downranked."
        ),
        SafetyItem(
            icon: "shield.checkered",
            iconColor: ClimbTheme.primaryColor,
            title: "Fully Consented",
            description: "Every photo is uploaded directly by the user, and we run light verification to keep bots and fake accounts out."
        ),
        SafetyItem(
            icon: "door.left.hand.open",
            iconColor: ClimbTheme.textMain,
            title: "Instant Exit",
            description: "You can delete your account and wipe all your data from our servers instantly in settings at any moment."
        ),
        SafetyItem(
            icon: "exclamationmark.triangle.fill",
            iconColor: Color(red: 1, green: 0.8, blue: 0),
            title: "Fast Reporting",
            description: "Anyone can report a photo or user with one tap, and we review them fast."
        ),
        SafetyItem(
            icon: "crown.fill",
            iconColor: Color(red: 1, green: 0.8, blue: 0),
            title: "Club Control",
            description: "Club leaders can kick anyone out of their club at any second."
        ),
        SafetyItem(
            icon: "nosign",
            iconColor: ClimbTheme.errorColor,
            title: "Standard Block & Mute",
            description: "Simple button to block someone so they never see your face or show up on your feed again."
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(item.iconColor)
                                .frame(width: 36, height: 36)
                                .background(ClimbTheme.bgPrimary)
                                .overlay(
                                    Rectangle()
                                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(ClimbTheme.displayFont(size: 15))
                                    .foregroundColor(ClimbTheme.textMain)

                                Text(item.description)
                                    .font(ClimbTheme.bodyFont(size: 13))
                                    .foregroundColor(ClimbTheme.textMuted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    // Contact Support button
                    Button(action: openSupportEmail) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                            Text("Contact Support")
                                .font(ClimbTheme.bodyFont(size: 14))
                                .fontWeight(.bold)
                        }
                    }
                    .buttonStyle(BrutalistSecondaryButtonStyle(isFullWidth: true))
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(ClimbTheme.bgSecondary)
            .navigationTitle("Safety Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.title2)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                }
            }
            }
        }
    }

    private func openSupportEmail() {
        if let url = URL(string: "mailto:anything@vexaiulkoo.resend.app?subject=Climb%20App%20Support") {
            UIApplication.shared.open(url)
        }
    }
}
