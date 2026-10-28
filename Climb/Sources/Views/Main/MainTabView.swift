import SwiftUI

/// Custom bottom tab bar matching the web's .bottom-nav
/// Implements navigation locks (Summit/Clubs locked until 25 votes)
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

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
            // Main content (scrolls behind the liquid glass bottom bar)
            Group {
                switch appState.selectedTab {
                case .mash:
                    MashView()
                case .leaderboard:
                    LeaderboardView()
                case .clubs:
                    ClubsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80) // Space for floating liquid glass nav bar

            // Apple Liquid Glass Bottom Navigation Bar
            liquidGlassBottomBar
        }
        .background(ClimbTheme.bgPrimary)
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay {
            if showSummitUnlockConfirm {
                BrutalistUnlockModal(
                    title: "ENTER SUMMIT",
                    message: "Access the Summit leaderboard for 25 Steps.",
                    cost: 25,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    confirmTitle: "Enter Summit (25 Steps)",
                    onUnlock: {
                        showSummitUnlockConfirm = false
                        Task {
                            let success = await appState.unlockFeature(id: "leaderboard", cost: 25)
                            if success { appState.selectedTab = .leaderboard }
                        }
                    },
                    onCancel: { showSummitUnlockConfirm = false }
                )
            }
        }
        .overlay {
            if showClubsUnlockConfirm {
                BrutalistUnlockModal(
                    title: "JOIN CLUBS",
                    message: "Access club climbing for 10 Steps.",
                    cost: 10,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    confirmTitle: "Join Clubs (10 Steps)",
                    onUnlock: {
                        showClubsUnlockConfirm = false
                        Task {
                            let success = await appState.unlockFeature(id: "clubs", cost: 10)
                            if success { appState.selectedTab = .clubs }
                        }
                    },
                    onCancel: { showClubsUnlockConfirm = false }
                )
            }
        }
        .task {
            await appState.loadNextMatchup()
        }
    }

    // MARK: - Apple Liquid Glass Bottom Bar

    private var liquidGlassBottomBar: some View {
        VStack(spacing: 0) {
            // Specular top rim line (liquid glass highlight)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.8),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Four tab options
            HStack(spacing: 6) {
                tabButton(tab: .mash, icon: "triangle.fill", label: "Climb")
                tabButton(
                    tab: .leaderboard,
                    icon: "trophy.fill",
                    label: isSummitUnlocked ? "Summit" : "25 Steps",
                    locked: !isSummitUnlocked,
                    onTapLocked: {
                        let avail = appState.currentProfile?.availableSteps ?? 0
                        if avail < 25 {
                            appState.showToastMessage("Need 25 Steps to access Summit (you have \(avail) Steps).", type: .error)
                        } else {
                            showSummitUnlockConfirm = true
                        }
                    }
                )
                tabButton(
                    tab: .clubs,
                    icon: "person.3.fill",
                    label: isClubsUnlocked ? "Clubs" : "10 Steps",
                    locked: !isClubsUnlocked,
                    onTapLocked: {
                        let avail = appState.currentProfile?.availableSteps ?? 0
                        if avail < 10 {
                            appState.showToastMessage("Need 10 Steps to access Clubs (you have \(avail) Steps).", type: .error)
                        } else {
                            showClubsUnlockConfirm = true
                        }
                    }
                )
                tabButton(tab: .profile, icon: "person.fill", label: "Me")
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 22) // Ergonomic spacing above home indicator
        }
        .background {
            ZStack {
                // Apple Ultra Thin Material for real-time backdrop blur
                Rectangle()
                    .fill(.ultraThinMaterial)

                // Liquid glass specular gradient wash
                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.35),
                        Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Translucent refraction tint
                Rectangle()
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(0.3)
                            : Color(red: 0.92, green: 0.95, blue: 0.99).opacity(0.4)
                    )
            }
        }
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.08),
            radius: 16,
            x: 0,
            y: -4
        )
    }

    private func tabButton(tab: AppState.AppTab, icon: String, label: String, locked: Bool = false, onTapLocked: (() -> Void)? = nil) -> some View {
        Button(action: {
            if locked {
                onTapLocked?()
                return
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                appState.selectedTab = tab
            }
        }) {
            let isSelected = appState.selectedTab == tab
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                    .foregroundColor(isSelected ? ClimbTheme.accentColor : ClimbTheme.textMuted)

                if locked {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(ClimbTheme.textMuted)
                        Text(label)
                            .font(ClimbTheme.bodyFont(size: 11))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                } else {
                    Text(label)
                        .font(ClimbTheme.bodyFont(size: 11))
                        .fontWeight(isSelected ? .bold : .semibold)
                        .foregroundColor(isSelected ? ClimbTheme.textMain : ClimbTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    // Liquid glass active pill lens
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ClimbTheme.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.4 : 0.8),
                                            ClimbTheme.accentColor.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            }
            .opacity(locked ? 0.35 : 1.0)
            .grayscale(locked ? 1.0 : 0)
        }
        .buttonStyle(.plain)
    }
}
