import SwiftUI

/// Challenges screen — static "Coming Soon" placeholder
/// Matches the web's screen-challenges
struct ChallengesView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("CHALLENGES")
                    .font(ClimbTheme.logoFont(size: 44))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Text("Exclusive opportunities for top climbers")
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)

            // Coming Soon content
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(ClimbTheme.primaryColor)

                Text("Coming Soon")
                    .font(ClimbTheme.displayFont(size: 40))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .textCase(.uppercase)

                Text("The top 99 climbers in each region will be eligible for exclusive casting calls and modeling opportunities in their area.")
                    .font(ClimbTheme.bodyFont(size: 15))
                    .foregroundColor(ClimbTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // Features list
                VStack(spacing: 12) {
                    featureRow(icon: "camera.fill", text: "Modeling Opportunities")
                    featureRow(icon: "video.fill", text: "Casting Calls")
                    featureRow(icon: "mappin.circle.fill", text: "Region-Based Matching")
                }
                .frame(maxWidth: 300)

                Text("Keep climbing to secure your spot in the top 99!")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .foregroundColor(ClimbTheme.textMuted)
                    .italic()
                    .padding(.top, 12)

                Spacer()
            }
            .opacity(0.65)
            .saturation(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
    }

    @ViewBuilder
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(ClimbTheme.primaryColor)

            Text(text)
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMain)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }
}
