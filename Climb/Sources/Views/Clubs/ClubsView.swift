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
    @State private var showSchoolModal = false

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
        .sheet(isPresented: $showSchoolModal) {
            JoinSchoolSheet()
                .environmentObject(appState)
        }
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
                // Join Your School
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        ZStack {
                            Rectangle()
                                .fill(ClimbTheme.primaryColor)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                                )
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Join Your School")
                                .font(ClimbTheme.displayFont(size: 22))
                                .foregroundColor(ClimbTheme.textMain)
                            Text("Connect and climb with students at your university")
                                .font(ClimbTheme.bodyFont(size: 12))
                                .foregroundColor(ClimbTheme.textMuted)
                        }
                        Spacer()
                    }

                    Button(action: {
                        showSchoolModal = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .bold))
                            Text("Find Your School")
                        }
                    }
                    .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                }
                .brutalistCard(padding: 24)

                // OR divider
                Text("— OR —")
                    .font(ClimbTheme.bodyFont(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(ClimbTheme.textMuted)

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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
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
            let errString = "\(error)"
            if errString.localizedCaseInsensitiveContains("100 votes") {
                appState.showToastMessage("You must cast at least 100 votes to access Clubs.", type: .error)
            } else if errString.localizedCaseInsensitiveContains("leave your current club") {
                appState.showToastMessage("You must leave your current club before joining another.", type: .error)
            } else {
                appState.showToastMessage("No club code found", type: .error)
            }
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

/// School option model
struct SchoolOptionItem: Identifiable {
    let id: String
    let name: String
    let code: String
    let emailDomain: String
}

private let availableSchoolsList: [SchoolOptionItem] = [
    SchoolOptionItem(
        id: "uatx",
        name: "University of Austin (UATX)",
        code: "UATX",
        emailDomain: "@student.uaustin.org"
    ),
    SchoolOptionItem(
        id: "utaustin",
        name: "UT Austin",
        code: "UTAUSTIN",
        emailDomain: "@my.utexas.edu"
    )
]

/// Sheet modal for searching and joining a school club via school email
struct JoinSchoolSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""
    @State private var selectedSchool: SchoolOptionItem?
    @State private var emailInput = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var filteredSchools: [SchoolOptionItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return availableSchoolsList
        }
        return availableSchoolsList.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed) ||
            $0.code.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let school = selectedSchool {
                    emailVerificationView(for: school)
                } else {
                    schoolListView
                }
            }
            .background(ClimbTheme.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedSchool != nil ? "VERIFY SCHOOL EMAIL" : "JOIN YOUR SCHOOL")
                        .font(ClimbTheme.bodyFont(size: 16))
                        .fontWeight(.bold)
                        .tracking(0.5)
                        .foregroundColor(ClimbTheme.textMain)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.title2)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                }
            }
        }
    }

    private var schoolListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Search box
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ClimbTheme.textMuted)
                    TextField("Search your school...", text: $searchText)
                        .font(ClimbTheme.bodyFont(size: 15))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ClimbTheme.textMuted)
                        }
                    }
                }
                .padding(12)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )

                // List of schools
                if filteredSchools.isEmpty {
                    VStack(spacing: 10) {
                        Text("No schools found")
                            .font(ClimbTheme.displayFont(size: 18))
                            .foregroundColor(ClimbTheme.textMain)
                        Text("We couldn't find a school matching \"\(searchText)\".")
                            .font(ClimbTheme.bodyFont(size: 13))
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                    .padding(.vertical, 30)
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredSchools) { school in
                            Button(action: {
                                selectedSchool = school
                                emailInput = ""
                                errorMessage = nil
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Rectangle()
                                            .fill(ClimbTheme.primaryColor)
                                            .frame(width: 38, height: 38)
                                            .overlay(
                                                Rectangle().stroke(ClimbTheme.borderColor, lineWidth: 2)
                                            )
                                        Image(systemName: "building.columns.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(school.name)
                                            .font(ClimbTheme.bodyFont(size: 15))
                                            .fontWeight(.bold)
                                            .foregroundColor(ClimbTheme.textMain)
                                            .multilineTextAlignment(.leading)
                                        Text("Official School Club")
                                            .font(ClimbTheme.bodyFont(size: 12))
                                            .foregroundColor(ClimbTheme.textMuted)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(ClimbTheme.textMuted)
                                }
                                .padding(14)
                                .background(ClimbTheme.bgSecondary)
                                .overlay(
                                    Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Coming soon banner
                HStack(spacing: 10) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 16))
                        .foregroundColor(ClimbTheme.accentColor)

                    Text("More schools coming soon.")
                        .font(ClimbTheme.bodyFont(size: 13))
                        .fontWeight(.bold)
                        .foregroundColor(ClimbTheme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle().stroke(ClimbTheme.borderColor.opacity(0.4), lineWidth: 1.5)
                )
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func emailVerificationView(for school: SchoolOptionItem) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Back button
                HStack {
                    Button(action: {
                        selectedSchool = nil
                        errorMessage = nil
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("All Schools")
                                .font(ClimbTheme.bodyFont(size: 14))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(ClimbTheme.primaryColor)
                    }
                    Spacer()
                }

                // School Info Box
                VStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 36))
                        .foregroundColor(ClimbTheme.primaryColor)

                    Text(school.name)
                        .font(ClimbTheme.displayFont(size: 22))
                        .foregroundColor(ClimbTheme.textMain)
                        .multilineTextAlignment(.center)

                    Text("Enter your school email address to verify student access and join this club.")
                        .font(ClimbTheme.bodyFont(size: 13))
                        .foregroundColor(ClimbTheme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )

                // Input Box
                VStack(alignment: .leading, spacing: 10) {
                    Text("SCHOOL EMAIL ADDRESS")
                        .font(ClimbTheme.bodyFont(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(ClimbTheme.textMuted)
                        .tracking(0.5)

                    TextField("yourname@school.edu", text: $emailInput)
                        .font(ClimbTheme.bodyFont(size: 16))
                        .foregroundColor(ClimbTheme.textMain)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(12)
                        .background(ClimbTheme.bgPrimary)
                        .overlay(
                            Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                        )

                    if let err = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                            Text(err)
                                .font(ClimbTheme.bodyFont(size: 13))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(ClimbTheme.errorColor)
                        .padding(.top, 2)
                    }
                }
                .padding(20)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle().stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )

                Button(action: {
                    verifyAndJoin(school: school)
                }) {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.black)
                        } else {
                            Text("Verify & Join Club")
                        }
                    }
                }
                .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                .disabled(emailInput.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
            }
            .padding(20)
        }
    }

    private func verifyAndJoin(school: SchoolOptionItem) {
        let clean = emailInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let requiredSuffix = school.emailDomain.lowercased()

        // Strict suffix check. If incorrect, show ONLY "Could not verify your email."
        guard clean.hasSuffix(requiredSuffix), clean.count > requiredSuffix.count else {
            errorMessage = "Could not verify your email."
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await appState.joinSchoolClub(name: school.name, code: school.code)
                appState.showToastMessage("Welcome to \(school.name)!", type: .success)
                dismiss()
            } catch {
                errorMessage = "Failed to join club. Please try again."
            }
            isSubmitting = false
        }
    }
}
