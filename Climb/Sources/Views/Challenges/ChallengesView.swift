import SwiftUI

/// Challenges view for modeling and casting opportunities
struct ChallengesView: View {
    @AppStorage("has_seen_challenges_explainer") private var hasSeenExplainer: Bool = false
    @State private var showExplainer: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Top Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("CHALLENGES")
                        .font(ClimbTheme.logoFont(size: 40))
                        .foregroundColor(ClimbTheme.primaryColor)
                        .shadow(color: .black, radius: 0, x: 2, y: 2)

                    Text("Exclusive modeling & casting invites")
                        .font(ClimbTheme.bodyFont(size: 13))
                        .foregroundColor(ClimbTheme.textMuted)
                }
                .padding(.top, 16)

                // ACTIVE OPPORTUNITIES SECTION
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("ACTIVE OPPORTUNITIES")
                            .font(ClimbTheme.displayFont(size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.primaryColor)
                    }

                    // Side-Eye Agency Card
                    sideEyeAgencyCard
                }

                // UPCOMING OPPORTUNITIES SECTION
                VStack(alignment: .leading, spacing: 12) {
                    Text("UPCOMING OPPORTUNITIES")
                        .font(ClimbTheme.displayFont(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(ClimbTheme.primaryColor)

                    // 2 Blank / Placeholder Rectangles
                    upcomingOpportunityCard(title: "Upcoming Opportunities")
                    upcomingOpportunityCard(title: "Upcoming Opportunities")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(ClimbTheme.bgPrimary)
        .onAppear {
            if !hasSeenExplainer {
                showExplainer = true
            }
        }
        .sheet(isPresented: $showExplainer) {
            ChallengesExplainerSheet(isPresented: $showExplainer, onAccept: {
                hasSeenExplainer = true
                showExplainer = false
            })
        }
    }

    // Side-Eye Agency Card Component
    private var sideEyeAgencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Side-Eye")
                            .font(ClimbTheme.displayFont(size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.textMain)

                        Text("IN-HOUSE")
                            .font(ClimbTheme.bodyFont(size: 10))
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(ClimbTheme.primaryColor)
                            .foregroundColor(.white)
                    }

                    Text("Our in house talent agency")
                        .font(ClimbTheme.bodyFont(size: 14))
                        .foregroundColor(ClimbTheme.textMuted)
                }

                Spacer()

                // Web Icon & Link
                Link(destination: URL(string: "https://side-eye.xyz")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .bold))
                        Text("side-eye.xyz")
                            .font(ClimbTheme.bodyFont(size: 12))
                            .fontWeight(.bold)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ClimbTheme.bgPrimary)
                    .foregroundColor(ClimbTheme.primaryColor)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: 2)
                    )
                }
            }

            Text("Recruiting top-voted models & talent directly through Climb regional leaderboards.")
                .font(ClimbTheme.bodyFont(size: 13))
                .foregroundColor(ClimbTheme.textMain)
                .lineLimit(3)
        }
        .padding(16)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
        .shadow(color: .black, radius: 0, x: 3, y: 3)
    }

    // Blank / Placeholder Card Component
    private func upcomingOpportunityCard(title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(ClimbTheme.displayFont(size: 16))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .padding(18)
        .background(ClimbTheme.bgSecondary.opacity(0.5))
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
        )
    }
}

/// First-time Onboarding Explainer Sheet
struct ChallengesExplainerSheet: View {
    @Binding var isPresented: Bool
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 10)

            // Retro Icon Box
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(ClimbTheme.primaryColor)
                .frame(width: 50, height: 50)
                .background(ClimbTheme.bgPrimary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )

            // Header Title
            VStack(spacing: 8) {
                Text("MODELING & CASTING")
                    .font(ClimbTheme.displayFont(size: 24))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .multilineTextAlignment(.center)

                Text("OPPORTUNITIES")
                    .font(ClimbTheme.displayFont(size: 20))
                    .foregroundColor(ClimbTheme.accentColor)
                    .multilineTextAlignment(.center)
            }

            // Explainer Box
            VStack(alignment: .leading, spacing: 16) {
                explainerRow(
                    icon: "mappin.and.ellipse",
                    title: "Regional Invites",
                    text: "Top users from select regions will receive invites to modeling and casting opportunities."
                )

                explainerRow(
                    icon: "location.fill",
                    title: "Select Your Region",
                    text: "Please select the region most accurate for you in your settings so local opportunities reach you."
                )

                explainerRow(
                    icon: "envelope.badge.fill",
                    title: "Check Your Email",
                    text: "Periodically check the email account you used to sign up, as this is where you will be invited."
                )
            }
            .padding(18)
            .background(ClimbTheme.bgSecondary)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )

            Spacer()

            // Accept Button
            Button(action: onAccept) {
                Text("I Understand")
                    .font(ClimbTheme.displayFont(size: 16))
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
            .padding(.bottom, 20)
        }
        .padding(24)
        .background(ClimbTheme.bgPrimary)
    }

    private func explainerRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ClimbTheme.primaryColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(ClimbTheme.bodyFont(size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.textMain)

                Text(text)
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
