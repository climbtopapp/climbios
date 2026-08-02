import SwiftUI

/// Custom bottom tab bar matching the web's .bottom-nav
/// Implements navigation locks (Summit/Clubs locked until 25 votes)
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    @State private var showSummitUnlockConfirm = false
    @State private var showClubsUnlockConfirm = false

    private var isSummitUnlocked: Bool {
        appState.currentProfile?.isUnlocked("leaderboard") ?? false
    }

    private var isClubsUnlocked: Bool {
        appState.currentProfile?.isUnlocked("clubs") ?? false
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
                tabButton(
                    tab: .leaderboard,
                    icon: "trophy.fill",
                    label: isSummitUnlocked ? "Summit" : "🔒 25 Steps",
                    locked: !isSummitUnlocked,
                    onTapLocked: {
                        let avail = appState.currentProfile?.availableSteps ?? 0
                        if avail < 25 {
                            appState.showToastMessage("Need 25 Steps to unlock Summit. (You have \(avail) Steps)", type: .error)
                        } else {
                            showSummitUnlockConfirm = true
                        }
                    }
                )
                tabButton(tab: .challenges, icon: "sparkles", label: "Challenges")
                tabButton(
                    tab: .clubs,
                    icon: "person.3.fill",
                    label: isClubsUnlocked ? "Clubs" : "🔒 10 Steps",
                    locked: !isClubsUnlocked,
                    onTapLocked: {
                        let avail = appState.currentProfile?.availableSteps ?? 0
                        if avail < 10 {
                            appState.showToastMessage("Need 10 Steps to unlock Clubs. (You have \(avail) Steps)", type: .error)
                        } else {
                            showClubsUnlockConfirm = true
                        }
                    }
                )
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
        .confirmationDialog("Unlock Summit", isPresented: $showSummitUnlockConfirm, titleVisibility: .visible) {
            Button("Unlock Summit (25 Steps)") {
                Task {
                    let success = await appState.unlockFeature(id: "leaderboard", cost: 25)
                    if success { appState.selectedTab = .leaderboard }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlock the Summit (Leaderboard) for 25 Steps?\n(Your Steps: \(appState.currentProfile?.availableSteps ?? 0))")
        }
        .confirmationDialog("Unlock Clubs", isPresented: $showClubsUnlockConfirm, titleVisibility: .visible) {
            Button("Unlock Clubs (10 Steps)") {
                Task {
                    let success = await appState.unlockFeature(id: "clubs", cost: 10)
                    if success { appState.selectedTab = .clubs }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlock Clubs for 10 Steps?\n(Your Steps: \(appState.currentProfile?.availableSteps ?? 0))")
        }
        .task {
            await appState.loadNextMatchup()
        }
    }

    private func tabButton(tab: AppState.AppTab, icon: String, label: String, locked: Bool = false, onTapLocked: (() -> Void)? = nil) -> some View {
        Button(action: {
            if locked {
                onTapLocked?()
                return
            }
            appState.selectedTab = tab
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
