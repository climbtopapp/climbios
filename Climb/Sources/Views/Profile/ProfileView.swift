import SwiftUI

/// Profile / Me screen
/// Matches the web's screen-profile
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var storeKit = StoreKitManager.shared

    @State private var rankStats: UserRankStats?
    @State private var isLoadingProfile = false
    @State private var showPurchaseSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileCard
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showPurchaseSheet) {
            PersonalGradePurchaseSheet(storeKit: storeKit)
        }
        .task { await loadProfile() }
    }

    private var profileCard: some View {
        VStack(spacing: 0) {
            // Profile header
            VStack(spacing: 8) {
                // Avatar
                AsyncImage(url: URL(string: appState.currentProfile?.avatarUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Rectangle()
                            .fill(ClimbTheme.bgPrimary)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(ClimbTheme.accentColor)
                            )
                    }
                }
                .frame(width: 110, height: 110)
                .clipped()
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.primaryColor, lineWidth: ClimbTheme.borderWidth)
                )

                // Name
                Text(appState.currentProfile?.firstName ?? maskEmail(appState.currentProfile?.email))
                    .font(ClimbTheme.displayFont(size: 28))
                    .foregroundColor(ClimbTheme.textMain)

                // Region
                Text("Region: \(appState.currentProfile?.state ?? "Unknown")")
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)

                // Settings button
                Button(action: { appState.showSettings = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text("Settings")
                    }
                }
                .buttonStyle(BrutalistSmallButtonStyle())
                .padding(.top, 4)
            }
            .padding(.bottom, 24)

            // Stats grid
            HStack(spacing: 16) {
                let votes = appState.currentProfile?.votesCast ?? 0
                let isGradeLocked = votes < 100
                statBox(value: gradeDisplay, label: "Grade", isLocked: isGradeLocked)
                statBox(value: "\(votes)", label: "Votes Cast", isLocked: false)
            }
            .padding(.bottom, 24)

            // Rankings section
            ranksSection

            // Share Profile button
            Button(action: shareProfile) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Share Profile")
                }
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
            .padding(.top, 10)
        }
        .brutalistCard(padding: 24)
    }

    private var gradeDisplay: String {
        let votes = appState.currentProfile?.votesCast ?? 0
        if votes < 100 {
            return "\(100 - votes) more"
        }
        return eloToGrade(appState.currentProfile?.elo)
    }

    @ViewBuilder
    private func statBox(value: String, label: String, isLocked: Bool = false) -> some View {
        VStack(spacing: 2) {
            if isLocked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ClimbTheme.accentColor)
                    Text(value)
                        .font(ClimbTheme.displayFont(size: 18))
                        .foregroundColor(ClimbTheme.accentColor)
                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            } else {
                Text(value)
                    .font(ClimbTheme.displayFont(size: 24))
                    .foregroundColor(ClimbTheme.textMain)
                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            Text(label)
                .font(ClimbTheme.bodyFont(size: 12))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMuted)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }

    private var ranksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("YOUR RANKINGS")
                .font(ClimbTheme.bodyFont(size: 16))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.primaryColor)
                .textCase(.uppercase)
                .padding(.bottom, 8)

            Rectangle()
                .fill(ClimbTheme.borderColor)
                .frame(height: 2)
                .padding(.bottom, 12)

            rankItem(icon: "globe", label: "Global Rank", value: globalRankDisplay)

            Rectangle()
                .fill(ClimbTheme.borderColor)
                .frame(height: 2)
                .padding(.vertical, 8)
                .opacity(0.3)

            rankItem(icon: "mappin.circle.fill", label: "Region Rank", value: stateRankDisplay)

            Rectangle()
                .fill(ClimbTheme.borderColor)
                .frame(height: 2)
                .padding(.vertical, 8)
                .opacity(0.3)

            rankItem(icon: "person.3.fill", label: "Club Rank", value: clubRankDisplay)
        }
        .padding(16)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }

    @ViewBuilder
    private func rankItem(icon: String, label: String, value: String) -> some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(ClimbTheme.textMuted)
                Text(label)
                    .font(ClimbTheme.bodyFont(size: 14))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            Spacer()
            Text(value)
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMain)
        }
        .padding(.vertical, 4)
    }

    private var globalRankDisplay: String {
        let votes = appState.currentProfile?.votesCast ?? 0
        if votes < 500 { return "\(500 - votes) more votes needed" }
        if let stats = rankStats, let r = stats.globalRank, let t = stats.totalGlobal, t > 0 {
            return "\(r) / \(t)"
        }
        return "--"
    }

    private var stateRankDisplay: String {
        let votes = appState.currentProfile?.votesCast ?? 0
        if votes < 500 { return "\(500 - votes) more votes needed" }
        if let stats = rankStats, let r = stats.stateRank, let t = stats.totalState, t > 0 {
            return "\(r) / \(t)"
        }
        return "--"
    }

    private var clubRankDisplay: String {
        let votes = appState.currentProfile?.votesCast ?? 0
        if votes < 500 { return "\(500 - votes) more votes needed" }
        guard appState.currentClubInfo != nil else { return "No Club" }
        if let myIndex = appState.currentClubMembers.firstIndex(where: { $0.userId == appState.currentUser?.id }) {
            return "\(myIndex + 1) / \(appState.currentClubMembers.count)"
        }
        return "--"
    }

    // MARK: - Actions

    private func loadProfile() async {
        isLoadingProfile = true
        await appState.fetchUserProfile()
        rankStats = await appState.loadUserRanks()
        isLoadingProfile = false
    }

    private func shareProfile() {
        guard let profile = appState.currentProfile else { return }

        let firstName = profile.firstName ?? "A climber"
        let eloGrade = gradeDisplay
        let globalRank = globalRankDisplay

        let shareText = "Check out \(firstName)'s profile on Climb! Current Grade: \(eloGrade) (Global Rank: #\(globalRank)). Join Climb to step up and make your way to the top!\n\nhttps://climb.side-eye.xyz"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// Purchase sheet modal for unlocking Personal Grade via StoreKit 2
struct PersonalGradePurchaseSheet: View {
    @ObservedObject var storeKit: StoreKitManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 10)

            // Header Icon Box
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(ClimbTheme.accentColor)
                .frame(width: 50, height: 50)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )

            // Header
            VStack(spacing: 8) {
                Text("UNLOCK PERSONAL GRADE")
                    .font(ClimbTheme.displayFont(size: 24))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .multilineTextAlignment(.center)

                Text("Find out your official letter grade based on head-to-head match votes across Climb!")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .foregroundColor(ClimbTheme.textMuted)
                    .multilineTextAlignment(.center)
            }

            // Price tag box
            VStack(spacing: 4) {
                Text("PERSONAL GRADE")
                    .font(ClimbTheme.bodyFont(size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.textMuted)
                    .textCase(.uppercase)

                Text("$0.99")
                    .font(ClimbTheme.displayFont(size: 42))
                    .foregroundColor(ClimbTheme.accentColor)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Text("One-time purchase • Lifetime access")
                    .font(ClimbTheme.bodyFont(size: 12))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(ClimbTheme.bgSecondary)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )

            // Feature Highlights
            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "star.fill", text: "Reveal your official Letter Grade (A+, A, B, C...)")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Real-time ELO rating score calculation")
                featureRow(icon: "trophy.fill", text: "Compare your score on Global & Regional leaderboards")
            }
            .padding(.vertical, 8)

            if let errorMsg = storeKit.errorMessage {
                Text(errorMsg)
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        let success = await storeKit.purchaseGrade()
                        if success {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if storeKit.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Unlock for $0.99")
                        }
                    }
                }
                .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                .disabled(storeKit.isLoading)

                Button("Restore Purchases") {
                    Task {
                        await storeKit.restorePurchases()
                        if storeKit.isGradePurchased {
                            dismiss()
                        }
                    }
                }
                .buttonStyle(BrutalistTextButtonStyle())
                .disabled(storeKit.isLoading)

                Button("Maybe Later") {
                    dismiss()
                }
                .font(ClimbTheme.bodyFont(size: 13))
                .foregroundColor(ClimbTheme.textMuted)
                .padding(.top, 4)
            }
        }
        .padding(24)
        .background(ClimbTheme.bgPrimary)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(ClimbTheme.primaryColor)
                .frame(width: 24)
            Text(text)
                .font(ClimbTheme.bodyFont(size: 13))
                .foregroundColor(ClimbTheme.textMain)
        }
    }
}
