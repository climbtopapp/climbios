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
            // Main content (scrolls continuously behind the floating liquid glass dock)
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Insets scrollable lists so bottom items can scroll above the dock,
                // while letting content physically scroll underneath the floating glass dock
                Color.clear
                    .frame(height: 76)
            }

            // Apple Floating Liquid Glass Dock
            liquidGlassFloatingDock
        }
        .background(ClimbTheme.bgPrimary)
        .ignoresSafeArea(.keyboard)
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

    // MARK: - Apple Floating Liquid Glass Dock

    private var liquidGlassFloatingDock: some View {
        HStack(spacing: 4) {
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
        .padding(.vertical, 8)
        .background {
            // 1. Apple Ultra Thin Material (real-time hardware backdrop blur)
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)

            // 2. Liquid specular sheen gradient
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.16 : 0.45), location: 0.0),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.14), location: 0.35),
                            .init(color: Color.clear, location: 0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 3. Dynamic glass refraction tint
            Capsule(style: .continuous)
                .fill(
                    colorScheme == .dark
                        ? Color.black.opacity(0.35)
                        : Color(red: 0.94, green: 0.96, blue: 1.0).opacity(0.35)
                )
        }
        .overlay {
            // 4. 360° Specular Fresnel edge refraction bevel
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.65 : 0.90), location: 0.0),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.22 : 0.45), location: 0.4),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.08 : 0.20), location: 0.8),
                            .init(color: Color.white.opacity(colorScheme == .dark ? 0.18 : 0.35), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        // 5. Deep floating ambient shadow
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.55 : 0.14),
            radius: 20,
            x: 0,
            y: 8
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.06),
            radius: 6,
            x: 0,
            y: 2
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(tab: AppState.AppTab, icon: String, label: String, locked: Bool = false, onTapLocked: (() -> Void)? = nil) -> some View {
        Button(action: {
            if locked {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                onTapLocked?()
                return
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                appState.selectedTab = tab
            }
        }) {
            let isSelected = appState.selectedTab == tab
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .foregroundColor(isSelected ? ClimbTheme.accentColor : ClimbTheme.textMuted)

                if locked {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                            .foregroundColor(ClimbTheme.textMuted)
                        Text(label)
                            .font(ClimbTheme.bodyFont(size: 10))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                } else {
                    Text(label)
                        .font(ClimbTheme.bodyFont(size: 10))
                        .fontWeight(isSelected ? .bold : .semibold)
                        .foregroundColor(isSelected ? ClimbTheme.textMain : ClimbTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background {
                if isSelected {
                    // Liquid glass active pill lens with spring physics
                    Capsule(style: .continuous)
                        .fill(ClimbTheme.accentColor.opacity(colorScheme == .dark ? 0.26 : 0.18))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(colorScheme == .dark ? 0.5 : 0.85),
                                            ClimbTheme.accentColor.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: ClimbTheme.accentColor.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 2)
                }
            }
            .opacity(locked ? 0.4 : 1.0)
            .grayscale(locked ? 1.0 : 0)
        }
        .buttonStyle(.plain)
    }
}
