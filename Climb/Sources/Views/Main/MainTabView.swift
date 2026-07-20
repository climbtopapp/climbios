import SwiftUI

/// Custom bottom tab bar matching the web's .bottom-nav
/// Implements navigation locks (Summit/Clubs locked until 25 votes)
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    private var votesNeeded: Int {
        let votes = appState.currentProfile?.votesCast ?? 0
        return max(0, 25 - votes)
    }

    private var isLocked: Bool {
        votesNeeded > 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch appState.selectedTab {
                case .mash:
                    MashView()
                case .leaderboard:
                    LeaderboardView()
                case .challenges:
                    ChallengesView()
                case .clubs:
                    ClubsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 72) // Space for nav bar

            // Bottom nav bar
            HStack(spacing: 0) {
                tabButton(tab: .mash, icon: "triangle.fill", label: "Climb")
                tabButton(tab: .leaderboard, icon: "trophy.fill", label: isLocked ? "\(votesNeeded) Votes" : "Summit", locked: isLocked)
                tabButton(tab: .challenges, icon: "sparkles", label: "Challenges")
                tabButton(tab: .clubs, icon: "person.3.fill", label: isLocked ? "\(votesNeeded) Votes" : "Clubs", locked: isLocked)
                tabButton(tab: .profile, icon: "person.fill", label: "Me")
            }
            .frame(height: 72)
            .background(ClimbTheme.bgSecondary)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(ClimbTheme.borderColor)
                    .frame(height: ClimbTheme.borderWidth)
            }
        }
        .background(ClimbTheme.bgPrimary)
        .ignoresSafeArea(.container, edges: .bottom)
        .task {
            await appState.loadNextMatchup()
        }
    }

    private func tabButton(tab: AppState.AppTab, icon: String, label: String, locked: Bool = false) -> some View {
        Button(action: {
            if locked {
                let votes = appState.currentProfile?.votesCast ?? 0
                let screenName = tab == .clubs ? "Clubs" : "the Summit"
                appState.showToastMessage("Cast \(25 - votes) more votes to unlock \(screenName).", type: .error)
                return
            }
            appState.selectedTab = tab
            if tab == .leaderboard {
                // Leaderboard will load in its onAppear
            } else if tab == .profile {
                // Profile will load in its onAppear
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(appState.selectedTab == tab ? 1.1 : 1.0)
                    .foregroundColor(appState.selectedTab == tab ? ClimbTheme.primaryColor : ClimbTheme.textMuted)

                Text(label)
                    .font(ClimbTheme.bodyFont(size: 11))
                    .fontWeight(.bold)
                    .foregroundColor(appState.selectedTab == tab ? ClimbTheme.accentColor : ClimbTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(appState.selectedTab == tab ? ClimbTheme.primaryLight : Color.clear)
            .opacity(locked ? 0.3 : 1.0)
            .grayscale(locked ? 1.0 : 0)
        }
        .buttonStyle(.plain)
    }
}
