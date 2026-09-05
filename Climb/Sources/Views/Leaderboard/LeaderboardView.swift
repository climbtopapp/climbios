import SwiftUI

/// Leaderboard / Summit screen
/// Matches the web's screen-leaderboard with Global/Region/Club tabs and gender filters
struct LeaderboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab = "Global"
    @State private var selectedGender = "everyone"
    @State private var leaderboardData: [LeaderboardRow] = []
    @State private var userRankStats: UserRankStats?
    @State private var isLoading = true
    @State private var showNoIgModal = false
    @State private var showIgUnlockModal = false
    @State private var showIgViewModal = false
    @State private var igViewHandle = ""
    @State private var targetIgUser: LeaderboardRow?

    private let genderOptions: [(label: String, value: String)] = [
        ("Everyone", "everyone"),
        ("Boys", "male"),
        ("Girls", "female")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("SUMMIT")
                    .font(ClimbTheme.logoFont(size: 44))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Text("Rankings update every hour")
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)

            // Tabs
            BrutalistTabs(
                tabs: ["Global", "Region", "Club"],
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 8)

            // Gender Filter Pills
            HStack(spacing: 8) {
                ForEach(genderOptions, id: \.value) { opt in
                    Button(action: {
                        selectedGender = opt.value
                    }) {
                        Text(opt.label)
                            .font(ClimbTheme.bodyFont(size: 13))
                            .fontWeight(.bold)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(selectedGender == opt.value ? ClimbTheme.primaryColor : ClimbTheme.bgSecondary)
                            .foregroundColor(ClimbTheme.textMain)
                            .overlay(
                                Rectangle()
                                    .stroke(ClimbTheme.borderColor, lineWidth: 2)
                            )
                    }
                }
            }
            .padding(.bottom, 12)

            // List
            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if leaderboardData.isEmpty {
                Spacer()
                Text("No ranked users yet.")
                    .font(ClimbTheme.bodyFont(size: 16))
                    .foregroundColor(ClimbTheme.textMuted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(leaderboardData.enumerated()), id: \.element.id) { index, row in
                            let isSelf = row.userId == appState.currentUser?.id
                            let votes = appState.currentProfile?.votesCast ?? 0
                            let displayRank = getRowRankDisplay(isSelf: isSelf, votes: votes, index: index, relativeRank: row.relativeRank)

                            RankRow(
                                rank: displayRank,
                                name: isSelf ? "You" : (row.firstName ?? "Climber"),
                                location: row.state ?? "Unknown State",
                                avatarUrl: row.avatarUrl,
                                rankIndex: index,
                                instagramHandle: row.instagramHandle,
                                onStarTap: isSelf ? nil : { handleIgClick(row: row) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }

            // Sticky user rank bar - ONLY display if user has unlocked ranks!
            if let profile = appState.currentProfile, !isLoading, profile.isUnlocked("ranks") {
                stickyUserRank(profile: profile)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
        .overlay {
            if showIgUnlockModal, let target = targetIgUser, let rawHandle = target.instagramHandle {
                let clean = rawHandle.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                BrutalistUnlockModal(
                    title: "UNLOCK INSTAGRAM",
                    message: "Unlock this user's Instagram profile for 25 Steps?",
                    cost: 25,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    onUnlock: {
                        let avail = appState.currentProfile?.availableSteps ?? 0
                        guard avail >= 25 else {
                            appState.showToastMessage("Need 25 Steps to unlock. (You have \(avail) Steps)", type: .error)
                            return
                        }
                        showIgUnlockModal = false
                        Task {
                            let success = await appState.unlockInstagram(targetUserId: target.userId, cost: 25)
                            if success {
                                igViewHandle = clean
                                showIgViewModal = true
                                await appState.sendProfileViewNotification(targetUserId: target.userId)
                            }
                        }
                    },
                    onCancel: { showIgUnlockModal = false }
                )
            }
        }
        .overlay {
            if showIgViewModal {
                BrutalistIgViewModal(
                    handle: igViewHandle,
                    onOpen: {
                        showIgViewModal = false
                        if let url = URL(string: "https://instagram.com/\(igViewHandle)") {
                            Task { @MainActor in await UIApplication.shared.open(url) }
                        }
                    },
                    onDismiss: { showIgViewModal = false }
                )
            }
        }
        .overlay {
            if showNoIgModal {
                BrutalistInfoModal(
                    title: "No Instagram Handle",
                    message: "This user has not added an Instagram handle to their profile yet.",
                    iconName: "star.fill",
                    onDismiss: { showNoIgModal = false }
                )
            }
        }
        .onChange(of: selectedTab) { _, _ in Task { await loadData() } }
        .onChange(of: selectedGender) { _, _ in Task { await loadData() } }
        .task { await loadData() }
    }

    private func getRowRankDisplay(isSelf: Bool, votes: Int, index: Int, relativeRank: Int?) -> String {
        if isSelf {
            if votes < 500 { return "--" }
            return relativeRank.map { "\($0)" } ?? "\(index + 1)"
        }
        return "\(index + 1)"
    }

    private func handleIgClick(row: LeaderboardRow) {
        guard let rawHandle = row.instagramHandle, !rawHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showNoIgModal = true
            return
        }

        let clean = rawHandle.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let isUnlocked = appState.currentProfile?.isInstagramUnlocked(row.userId) ?? false
        if isUnlocked {
            igViewHandle = clean
            showIgViewModal = true
            Task {
                await appState.sendProfileViewNotification(targetUserId: row.userId)
            }
            return
        }

        targetIgUser = row
        showIgUnlockModal = true
    }

    private var tabType: AppState.LeaderboardTab {
        switch selectedTab {
        case "Global": return .global
        case "Region": return .state
        case "Club": return .club
        default: return .global
        }
    }

    private func loadData() async {
        isLoading = true
        appState.currentLeaderboardTab = tabType
        appState.currentLeaderboardGender = selectedGender
        leaderboardData = await appState.loadLeaderboard()
        userRankStats = await appState.loadUserRanks()
        isLoading = false
    }

    private func stickyUserRank(profile: Profile) -> some View {
        let votes = profile.votesCast
        let myIndex = leaderboardData.firstIndex { $0.userId == appState.currentUser?.id }
        
        var displayRank = "--"
        var displayTotal = "--"
        var scopeLabel = ""
        
        if selectedTab == "Global" {
            scopeLabel = "Global"
            if let idx = myIndex {
                displayRank = leaderboardData[idx].relativeRank.map { "\($0)" } ?? "\(idx + 1)"
                displayTotal = "\(leaderboardData.count)"
            } else if let stats = userRankStats, let gr = stats.globalRank, gr > 0 {
                displayRank = "\(gr)"
                displayTotal = stats.totalGlobal.map { "\($0)" } ?? "--"
            }
        } else if selectedTab == "Region" {
            scopeLabel = appState.userState.isEmpty ? "Regional" : appState.userState
            if let idx = myIndex {
                displayRank = leaderboardData[idx].relativeRank.map { "\($0)" } ?? "\(idx + 1)"
                displayTotal = "\(leaderboardData.count)"
            } else if let stats = userRankStats, let sr = stats.stateRank, sr > 0 {
                displayRank = "\(sr)"
                displayTotal = stats.totalState.map { "\($0)" } ?? "--"
            }
        } else if selectedTab == "Club" {
            scopeLabel = appState.currentClubInfo?.name ?? "Club"
            if let idx = myIndex {
                displayRank = "\(idx + 1)"
                displayTotal = "\(leaderboardData.count)"
            }
        }

        return HStack(spacing: 12) {
            // Rank badge
            Text(votes < 500 ? "--" : displayRank)
                .font(ClimbTheme.displayFont(size: 22))
                .frame(width: 32, height: 28)
                .background(ClimbTheme.primaryColor)
                .foregroundColor(.black)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )

            // Avatar
            AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle().fill(ClimbTheme.bgPrimary)
                }
            }
            .frame(width: 44, height: 44)
            .clipped()
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: 2)
            )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text("You (My Position)")
                    .font(ClimbTheme.bodyFont(size: 15))
                    .fontWeight(.bold)

                Text(votes < 500 ?
                     "\(scopeLabel) (\(500 - votes) more votes needed)" :
                     "\(scopeLabel) (Rank #\(displayRank) of \(displayTotal))")
                    .font(ClimbTheme.bodyFont(size: 12))
                    .foregroundColor(ClimbTheme.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(ClimbTheme.primaryLight)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.primaryColor, lineWidth: ClimbTheme.borderWidth)
        )
    }
}
