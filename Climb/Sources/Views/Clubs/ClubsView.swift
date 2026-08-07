import SwiftUI

/// Clubs screen — join, create, manage clubs
/// Matches the web's screen-clubs with two states: no-club and has-club
struct ClubsView: View {
    @EnvironmentObject var appState: AppState

    @State private var joinCode = ""
    @State private var createName = ""
    @State private var isJoining = false
    @State private var isCreating = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showLeaveConfirm = false
    @State private var showUnlockModal = false

    private var isClubsUnlocked: Bool {
        appState.currentProfile?.isUnlocked("clubs") ?? false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("CLUBS")
                    .font(ClimbTheme.logoFont(size: 44))
                    .foregroundColor(ClimbTheme.primaryColor)
                    .shadow(color: .black, radius: 0, x: 2, y: 2)

                Text("Climb with your friends, school, or work.")
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)

            if !isClubsUnlocked {
                lockedClubView
            } else if appState.currentClubInfo != nil {
                hasClubView
            } else {
                noClubView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
        .task {
            if isClubsUnlocked {
                await appState.fetchClubInfo()
            }
        }
    }

    // MARK: - Locked View

    private var lockedClubView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(ClimbTheme.accentColor)

            Text("CLUBS LOCKED")
                .font(ClimbTheme.displayFont(size: 24))
                .foregroundColor(ClimbTheme.textMain)

            Text("Unlock Clubs for 10 Steps to join or create clubs and climb with your friends.")
                .font(ClimbTheme.bodyFont(size: 14))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                let avail = appState.currentProfile?.availableSteps ?? 0
                if avail < 10 {
                    appState.showToastMessage("Need 10 Steps to unlock Clubs. (You have \(avail) Steps)", type: .error)
                } else {
                    showUnlockModal = true
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("UNLOCK CLUBS (10 STEPS)")
                }
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: false))
            .padding(.horizontal, 32)

            Spacer()
        }
        .overlay {
            if showUnlockModal {
                BrutalistUnlockModal(
                    title: "UNLOCK CLUBS",
                    message: "Unlock Clubs for 10 Steps?",
                    cost: 10,
                    availableSteps: appState.currentProfile?.availableSteps ?? 0,
                    onUnlock: {
                        showUnlockModal = false
                        Task {
                            _ = await appState.unlockFeature(id: "clubs", cost: 10)
                        }
                    },
                    onCancel: { showUnlockModal = false }
                )
            }
        }
    }

    // MARK: - No Club View

    private var noClubView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Join a Club
                VStack(spacing: 15) {
                    Text("Join a Club")
                        .font(ClimbTheme.displayFont(size: 24))

                    TextField("Invite Code", text: $joinCode)
                        .font(ClimbTheme.bodyFont(size: 20))
                        .foregroundColor(ClimbTheme.textMain)
                        .tracking(2)
                        .textCase(.uppercase)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(ClimbTheme.bgPrimary)
                        .overlay(
                            Rectangle()
                                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                        )
                        .textInputAutocapitalization(.characters)
                        .onChange(of: joinCode) { _, newVal in
                            if newVal.count > 6 { joinCode = String(newVal.prefix(6)) }
                        }

                    Button(action: { Task { await joinClub() } }) {
                        if isJoining {
                            ProgressView().tint(.black)
                        } else {
                            Text("Join Club")
                        }
                    }
                    .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                    .disabled(joinCode.count != 6 || isJoining)
                }
                .brutalistCard(padding: 24)

                // OR divider
                Text("— OR —")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(ClimbTheme.textMuted)

                // Create a Club
                VStack(spacing: 15) {
                    Text("Create a Club")
                        .font(ClimbTheme.displayFont(size: 24))

                    Text("You can only create one club.")
                        .font(ClimbTheme.bodyFont(size: 12))
                        .foregroundColor(ClimbTheme.textMuted)

                    TextField("Club Name (e.g., UMich 2026)", text: $createName)
                        .font(ClimbTheme.bodyFont(size: 16))
                        .foregroundColor(ClimbTheme.textMain)
                        .padding(12)
                        .background(ClimbTheme.bgPrimary)
                        .overlay(
                            Rectangle()
                                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                        )
                        .onChange(of: createName) { _, newVal in
                            if newVal.count > 30 { createName = String(newVal.prefix(30)) }
                        }

                    Button(action: { Task { await createClub() } }) {
                        if isCreating {
                            ProgressView().tint(.black)
                        } else {
                            Text("Create Club")
                        }
                    }
                    .buttonStyle(BrutalistSecondaryButtonStyle(isFullWidth: true))
                    .disabled(createName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
                .brutalistCard(padding: 24)
            }
            .padding(20)
        }
    }

    // MARK: - Has Club View

    private var hasClubView: some View {
        VStack(spacing: 0) {
            // Club info card
            VStack(spacing: 10) {
                if isEditingName {
                    HStack(spacing: 10) {
                        TextField("Club Name", text: $editedName)
                            .font(ClimbTheme.bodyFont(size: 16))
                            .foregroundColor(ClimbTheme.textMain)
                            .padding(8)
                            .background(ClimbTheme.bgPrimary)
                            .overlay(
                                Rectangle()
                                    .stroke(ClimbTheme.borderColor, lineWidth: 2)
                            )

                        Button("Save") {
                            Task { await saveClubName() }
                        }
                        .buttonStyle(BrutalistSmallButtonStyle())
                    }
                } else {
                    HStack(spacing: 10) {
                        Text(appState.currentClubInfo?.name ?? "Club")
                            .font(ClimbTheme.displayFont(size: 24))
                            .fontWeight(.bold)

                        if isCreator {
                            Button("Edit") {
                                editedName = appState.currentClubInfo?.name ?? ""
                                isEditingName = true
                            }
                            .buttonStyle(BrutalistSmallButtonStyle())
                        }
                    }
                }

                // Invite code
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invite Code")
                            .font(ClimbTheme.bodyFont(size: 12))
                            .fontWeight(.bold)
                            .foregroundColor(ClimbTheme.textMuted)
                            .textCase(.uppercase)

                        Text(appState.currentClubInfo?.code ?? "------")
                            .font(.system(size: 22, weight: .heavy, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(ClimbTheme.primaryColor)
                    }

                    Spacer()

                    Button("Share") {
                        shareClubCode()
                    }
                    .buttonStyle(BrutalistSmallButtonStyle())
                }
                .padding(12)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8]))
                        .foregroundColor(ClimbTheme.borderColor)
                )

                Text("\(appState.currentClubMembers.count) members")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .foregroundColor(ClimbTheme.textMuted)
            }
            .brutalistCard(padding: 20)
            .padding(.horizontal, 20)

            // Members header
            Text("Members")
                .font(ClimbTheme.bodyFont(size: 16))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 10)

            // Members list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sortedMembers) { member in
                        memberRow(member: member)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Leave Club button
            VStack(spacing: 8) {
                Button("Leave Club") {
                    showLeaveConfirm = true
                }
                .font(ClimbTheme.bodyFont(size: 16))
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(ClimbTheme.errorColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.clear)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.errorColor, lineWidth: ClimbTheme.borderWidth)
                )

                if isCreator {
                    Text("Since you are the creator, leaving will delete the club.")
                        .font(ClimbTheme.bodyFont(size: 12))
                        .foregroundColor(ClimbTheme.errorColor)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
        .alert("Leave Club", isPresented: $showLeaveConfirm) {
            Button("Leave", role: .destructive) {
                Task { await leaveClub() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(isCreator ?
                 "Since you are the creator, this will permanently delete the club and remove all members." :
                 "Are you sure you want to leave this club?")
        }
    }

    private var isCreator: Bool {
        appState.currentClubInfo?.createdBy == appState.currentUser?.id
    }

    private var sortedMembers: [ClubMember] {
        appState.currentClubMembers.sorted { a, b in
            if a.userId == appState.currentClubInfo?.createdBy { return true }
            if b.userId == appState.currentClubInfo?.createdBy { return false }
            return (a.firstName ?? "").localizedCaseInsensitiveCompare(b.firstName ?? "") == .orderedAscending
        }
    }

    @ViewBuilder
    private func memberRow(member: ClubMember) -> some View {
        let isSelf = member.userId == appState.currentUser?.id
        let memberIsCreator = member.userId == appState.currentClubInfo?.createdBy

        HStack(spacing: 12) {
            AsyncImage(url: URL(string: member.avatarUrl ?? "")) { phase in
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

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(isSelf ? "You" : (member.firstName ?? "Member"))
                        .font(ClimbTheme.bodyFont(size: 15))
                        .fontWeight(.bold)

                    if memberIsCreator {
                        Text("(Creator)")
                            .font(ClimbTheme.bodyFont(size: 13))
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                }

                Text(member.state ?? "Unknown")
                    .font(ClimbTheme.bodyFont(size: 12))
                    .foregroundColor(ClimbTheme.textMuted)
            }

            Spacer()

            if isCreator && !isSelf {
                Button(action: {
                    Task { await removeMember(userId: member.userId) }
                }) {
                    Text("✕")
                        .foregroundColor(ClimbTheme.errorColor)
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
        )
    }

    // MARK: - Actions

    private func joinClub() async {
        let code = joinCode.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 6 else {
            appState.showToastMessage("Please enter a valid 6-character code", type: .error)
            return
        }

        isJoining = true
        do {
            try await appState.joinClub(code: code)
            appState.showToastMessage("Joined club successfully!", type: .success)
            joinCode = ""
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
        isJoining = false
    }

    private func createClub() async {
        let name = createName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        isCreating = true
        do {
            try await appState.createClub(name: name)
            appState.showToastMessage("Club created!", type: .success)
            createName = ""
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
        isCreating = false
    }

    private func leaveClub() async {
        do {
            try await appState.leaveClub()
            appState.showToastMessage(isCreator ? "Club deleted." : "You have left the club.", type: .success)
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
    }

    private func saveClubName() async {
        let newName = editedName.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }

        do {
            try await appState.updateClubName(newName)
            appState.showToastMessage("Club name updated", type: .success)
            isEditingName = false
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
    }

    private func removeMember(userId: UUID) async {
        do {
            try await appState.removeClubMember(userId: userId)
            appState.showToastMessage("Member removed", type: .success)
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
    }

    private func shareClubCode() {
        guard let club = appState.currentClubInfo else { return }
        let text = "Join my Climb club: \(club.name)! Invite Code: \(club.code)\n\nJoin here: https://climb.side-eye.xyz"

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
