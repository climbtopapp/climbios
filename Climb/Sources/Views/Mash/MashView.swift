import SwiftUI

/// Mash voting arena — the core voting screen
/// Matches the web's screen-mash with two cards to vote between
struct MashView: View {
    @EnvironmentObject var appState: AppState

    @State private var leftRotation = Double.random(in: -2...2)
    @State private var rightRotation = Double.random(in: -2...2)
    @State private var isVoting = false
    @State private var votedSide: String? = nil
    @State private var showBlockModal = false
    @State private var blockTargetId: UUID?
    @State private var leftImageLoaded = false
    @State private var rightImageLoaded = false

    private var hasMatchup: Bool {
        appState.currentMatchup.count >= 2
    }

    @State private var showSafety = false
    @State private var showNotifications = false
    @State private var showStepsExplainer = false
    @State private var showIgUnlockModal = false
    @State private var showNoIgModal = false
    @State private var showIgViewModal = false
    @State private var showClubsUnlockConfirm = false
    @State private var igViewHandle = ""
    @State private var igUnlockTarget: MatchupProfile?

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
            // Header tabs: Global / Club
            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Button(action: {
                        appState.isMashClubMode = false
                        Task { await appState.loadNextMatchup() }
                        randomizeRotations()
                    }) {
                        Text("Global")
                            .font(ClimbTheme.bodyFont(size: 14))
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(!appState.isMashClubMode ? .black : ClimbTheme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(!appState.isMashClubMode ? ClimbTheme.primaryColor : Color.clear)
                            .overlay(
                                Group {
                                    if !appState.isMashClubMode {
                                        Rectangle().stroke(ClimbTheme.borderColor, lineWidth: 2)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        let isClubsUnlocked = appState.currentProfile?.isUnlocked("clubs") ?? false
                        if !isClubsUnlocked {
                            let avail = appState.currentProfile?.availableSteps ?? 0
                            if avail < 10 {
                                appState.showToastMessage("Need 10 Steps to unlock Clubs. (You have \(avail) Steps)", type: .error)
                            } else {
                                showClubsUnlockConfirm = true
                            }
                            return
                        }
                        if appState.currentClubInfo == nil {
                            appState.showToastMessage("You must join a club first to climb against members.", type: .error)
                            appState.selectedTab = .clubs
                            return
                        }
                        appState.isMashClubMode = true
                        Task { await appState.loadNextMatchup() }
                        randomizeRotations()
                    }) {
                        Text("Club")
                            .font(ClimbTheme.bodyFont(size: 14))
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .foregroundColor(appState.isMashClubMode ? .black : ClimbTheme.textMuted)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(appState.isMashClubMode ? ClimbTheme.primaryColor : Color.clear)
                            .overlay(
                                Group {
                                    if appState.isMashClubMode {
                                        Rectangle().stroke(ClimbTheme.borderColor, lineWidth: 2)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )
                Spacer()
            }
            .padding(.top, 16)

            // Steps Counter Bar
            Button(action: { showStepsExplainer = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "shoeprints.fill")
                        .font(.system(size: 13))
                        .foregroundColor(ClimbTheme.primaryColor)
                    Text("\(appState.currentProfile?.availableSteps ?? 0) Steps")
                        .font(ClimbTheme.bodyFont(size: 13))
                        .fontWeight(.bold)
                        .foregroundColor(ClimbTheme.primaryColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            if hasMatchup {
                // Voting arena
                VStack(spacing: 12) {
                    Spacer()

                    // Left card
                    mashCard(
                        profile: appState.currentMatchup[0],
                        rotation: leftRotation,
                        side: "left",
                        isHighlighted: votedSide == "left"
                    )

                    OrDivider()

                    // Right card
                    mashCard(
                        profile: appState.currentMatchup[1],
                        rotation: rightRotation,
                        side: "right",
                        isHighlighted: votedSide == "right"
                    )

                    Spacer()
                }
                .padding(.horizontal, 24)
                .opacity(isVoting ? 0.3 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isVoting)
            } else {
                // No matchups view
                VStack(spacing: 16) {
                    Spacer()

                    VStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                            .foregroundColor(ClimbTheme.accentColor)

                        Text(appState.isMashClubMode ? "Not Enough Members" : "No Matchups Yet")
                            .font(ClimbTheme.displayFont(size: 22))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(appState.isMashClubMode ?
                             "There are not enough active members in this club with photos to vote on. Invite more club members to join!" :
                             "To start voting, invite more friends to join Climb and upload their photos!")
                            .font(ClimbTheme.bodyFont(size: 14))
                            .foregroundColor(ClimbTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .brutalistCard(padding: 40)
                    .frame(maxWidth: 400)

                    Spacer()
                }
                .padding(20)
            }
            }

            // Safety info button (?) in top-left
            Button(action: { showSafety = true }) {
                Text("?")
                    .font(ClimbTheme.displayFont(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.textMain)
                    .frame(width: 36, height: 36)
                    .background(ClimbTheme.bgSecondary)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                    )
            }
            .padding(.top, 16)
            .padding(.leading, 16)
            .buttonStyle(.plain)

            // Notifications button (🔔) in top-right
            HStack {
                Spacer()
                Button(action: {
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "climb_last_read_notifications")
                    showNotifications = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(ClimbTheme.textMain)
                            .frame(width: 36, height: 36)
                            .background(ClimbTheme.bgSecondary)
                            .overlay(
                                Rectangle()
                                    .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                            )
                        
                        if unreadNotificationsCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
        .sheet(isPresented: $showSafety) {
            SafetyInfoView()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsFeedView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showStepsExplainer) {
            StepsExplainerSheet()
                .environmentObject(appState)
        }
        .overlay {
            if showIgUnlockModal, let target = igUnlockTarget, let rawHandle = target.instagramHandle {
                let clean = rawHandle.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                BrutalistUnlockModal(
                    title: "UNLOCK INSTAGRAM",
                    message: "Unlock this user's Instagram profile for 25 Steps?",
                    cost: 25,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    onUnlock: {
                        showIgUnlockModal = false
                        Task {
                            let success = await appState.unlockInstagram(targetUserId: target.id, cost: 25)
                            if success {
                                igViewHandle = clean
                                showIgViewModal = true
                                await appState.sendProfileViewNotification(targetUserId: target.id)
                            }
                        }
                    },
                    onCancel: {
                        showIgUnlockModal = false
                    }
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
                    onDismiss: {
                        showIgViewModal = false
                    }
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
        .overlay {
            if showClubsUnlockConfirm {
                BrutalistUnlockModal(
                    title: "UNLOCK CLUBS",
                    message: "Unlock Clubs for 10 Steps?",
                    cost: 10,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    onUnlock: {
                        showClubsUnlockConfirm = false
                        Task {
                            let success = await appState.unlockFeature(id: "clubs", cost: 10)
                            if success && appState.currentClubInfo == nil {
                                appState.selectedTab = .clubs
                            }
                        }
                    },
                    onCancel: { showClubsUnlockConfirm = false }
                )
            }
        }
        .onAppear {
            Task {
                await appState.fetchNotifications()
            }
        }
        .overlay {
            if showBlockModal {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { showBlockModal = false }

                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36))
                            .foregroundColor(ClimbTheme.errorColor)

                        Text("BLOCK & REPORT")
                            .font(ClimbTheme.displayFont(size: 20))
                            .foregroundColor(ClimbTheme.textMain)
                            .multilineTextAlignment(.center)

                        Text("Are you sure you wish to block and report this user and their photo?")
                            .font(ClimbTheme.bodyFont(size: 14))
                            .foregroundColor(ClimbTheme.textMuted)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button(action: {
                                showBlockModal = false
                                blockTargetId = nil
                            }) {
                                Text("Cancel")
                                    .font(ClimbTheme.bodyFont(size: 14))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(BrutalistSmallButtonStyle())

                            Button(action: {
                                showBlockModal = false
                                if let id = blockTargetId {
                                    Task {
                                        await appState.blockUser(blockedId: id)
                                        await appState.loadNextMatchup()
                                        randomizeRotations()
                                    }
                                }
                            }) {
                                Text("Block & Report")
                                    .font(ClimbTheme.bodyFont(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(BrutalistDestructiveButtonStyle(isFullWidth: false))
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(ClimbTheme.bgSecondary)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                    )
                    .padding(.horizontal, 32)
                }
            }
        }
    }

    // MARK: - Mash Card

    @ViewBuilder
    private func mashCard(profile: MatchupProfile, rotation: Double, side: String, isHighlighted: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Image wrapper
                ZStack {
                    AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(ClimbTheme.textMuted)
                                Text("Image failed")
                                    .font(ClimbTheme.bodyFont(size: 12))
                                    .fontWeight(.bold)
                                    .textCase(.uppercase)
                                    .foregroundColor(ClimbTheme.textMuted)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(ClimbTheme.bgPrimary)
                        default:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(ClimbTheme.bgPrimary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(ClimbTheme.borderColor)
                        .frame(height: ClimbTheme.borderWidth)
                }
            }
            .frame(maxWidth: 240)
            .background(ClimbTheme.bgSecondary)
            .overlay(
                Rectangle()
                    .stroke(isHighlighted ? ClimbTheme.successColor : ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
            )
            .rotationEffect(.degrees(rotation))
            .onTapGesture {
                guard !isVoting else { return }
                recordVote(side: side)
            }

            // Block button
            Button(action: {
                blockTargetId = profile.id
                showBlockModal = true
            }) {
                Image(systemName: "nosign")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(ClimbTheme.errorColor)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: 2)
                    )
            }
            .offset(x: -48, y: 50)
            .rotationEffect(.degrees(-rotation)) // Counter-rotate

            // Instagram button
            let hasIg = profile.instagramHandle != nil && !profile.instagramHandle!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            Button(action: {
                handleInstagramTap(profile: profile)
            }) {
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(hasIg ? .black : ClimbTheme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(hasIg ? ClimbTheme.primaryColor : ClimbTheme.bgSecondary)
                    .opacity(hasIg ? 1.0 : 0.5)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: 2)
                    )
            }
            .offset(x: -48, y: 104)
            .rotationEffect(.degrees(-rotation))
        }
        .frame(maxWidth: .infinity)
    }

    private func handleInstagramTap(profile: MatchupProfile) {
        guard let rawHandle = profile.instagramHandle, !rawHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showNoIgModal = true
            return
        }
        let clean = rawHandle.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isUnlocked = appState.currentProfile?.isInstagramUnlocked(profile.id) ?? false
        if isUnlocked {
            igViewHandle = clean
            showIgViewModal = true
            Task {
                await appState.sendProfileViewNotification(targetUserId: profile.id)
            }
            return
        }

        igUnlockTarget = profile
        showIgUnlockModal = true
    }

    // MARK: - Actions

    private func recordVote(side: String) {
        guard appState.currentMatchup.count >= 2 else { return }

        isVoting = true
        votedSide = side

        let winnerId = side == "left" ? appState.currentMatchup[0].id : appState.currentMatchup[1].id
        let loserId = side == "left" ? appState.currentMatchup[1].id : appState.currentMatchup[0].id

        Task {
            await appState.castVote(winnerId: winnerId, loserId: loserId)

            try? await Task.sleep(for: .milliseconds(200))

            await appState.loadNextMatchup()
            randomizeRotations()
            votedSide = nil
            isVoting = false
        }
    }

    private func randomizeRotations() {
        leftRotation = Double.random(in: -2...2)
        rightRotation = Double.random(in: -2...2)
    }

    private var unreadNotificationsCount: Int {
        let lastRead = UserDefaults.standard.double(forKey: "climb_last_read_notifications")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return appState.notifications.filter { item in
            var date = formatter.date(from: item.createdAt)
            if date == nil {
                let fallback = ISO8601DateFormatter()
                date = fallback.date(from: item.createdAt)
            }
            guard let date = date else { return false }
            return date.timeIntervalSince1970 > lastRead
        }.count
    }
}

struct StepsExplainerSheet: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: 40))
                    .foregroundColor(ClimbTheme.primaryColor)

                Text("STEPS")
                    .font(ClimbTheme.displayFont(size: 24))
                    .foregroundColor(ClimbTheme.primaryColor)

                Text("You can spend your steps to gain access to new features and stars to use on other users.")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(ClimbTheme.textMain)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    featureRow(id: "leaderboard", icon: "trophy.fill", title: "Summit", cost: 25)
                    featureRow(id: "clubs", icon: "person.3.fill", title: "Clubs", cost: 10)
                    featureRow(id: "grade", icon: "chart.bar.fill", title: "Personal Grade", cost: 75)
                    featureRow(id: "ranks", icon: "list.number", title: "Official Ranks", cost: 250)

                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(ClimbTheme.primaryColor)
                            Text("View User Instagram")
                                .font(ClimbTheme.bodyFont(size: 13))
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Text("25 Steps / profile")
                            .font(ClimbTheme.bodyFont(size: 12))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                }
                .padding(16)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )
                .padding(.horizontal)

                Spacer()

                // Purchase 100 Steps Button
                Button(action: {
                    Task {
                        let success = await storeKit.purchase100Steps()
                        if success {
                            await appState.creditPurchasedSteps(amount: 100)
                        } else if let err = storeKit.errorMessage {
                            appState.showToastMessage(err, type: .error)
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if storeKit.isPurchasingSteps {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Purchase 100 Steps ($0.99)")
                        }
                    }
                }
                .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                .disabled(storeKit.isPurchasingSteps)
                .padding(.horizontal, 24)

                Button(action: { dismiss() }) {
                    Text("Close")
                }
                .buttonStyle(BrutalistSecondaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding(.top, 24)
            .background(ClimbTheme.bgPrimary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(ClimbTheme.textMuted)
                }
            }
        }
    }

    @ViewBuilder
    private func featureRow(id: String, icon: String, title: String, cost: Int) -> some View {
        let isUnlocked = appState.currentProfile?.isUnlocked(id) ?? false
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(ClimbTheme.primaryColor)
                Text(title)
                    .font(ClimbTheme.bodyFont(size: 13))
                    .fontWeight(.bold)
            }
            Spacer()
            if isUnlocked {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Unlocked")
                        .font(ClimbTheme.bodyFont(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            } else {
                Button(action: {
                    Task { _ = await appState.unlockFeature(id: id, cost: cost) }
                }) {
                    Text("Unlock (\(cost))")
                        .font(ClimbTheme.bodyFont(size: 12))
                        .fontWeight(.bold)
                }
                .buttonStyle(BrutalistSmallButtonStyle())
            }
        }
    }
}
