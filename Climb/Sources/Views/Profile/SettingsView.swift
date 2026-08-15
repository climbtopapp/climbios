import SwiftUI
import PhotosUI

/// Settings modal/sheet
/// Matches the web's settings-modal
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var votePref = "everyone"
    @State private var selectedCity: City?
    @State private var isSaving = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var rawImage: UIImage?
    @State private var showCropper = false
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteFinalConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    firstNameField
                    genderSection
                    votePrefSection
                    CityPickerView(selectedCity: $selectedCity)
                    saveButton
                    restorePurchasesButton
                    contactSupportButton
                    signOutButton
                    deleteAccountSection
                }
                .padding(20)
            }
            .background(ClimbTheme.bgSecondary)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.title2)
                            .foregroundColor(ClimbTheme.textMuted)
                    }
                }
            }
        }
        .onAppear { loadCurrentValues() }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    rawImage = uiImage
                    showCropper = true
                }
            }
        }
        .sheet(isPresented: $showCropper) {
            if let img = rawImage {
                ImageCropperView(image: img) { cropped in
                    Task { await uploadNewPhoto(cropped) }
                    showCropper = false
                }
            }
        }
        .alert("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await appState.signOut()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete Permanently", role: .destructive) {
                showDeleteFinalConfirm = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete your account? This cannot be undone. All your data, votes, photos, and club memberships will be erased.")
        }
        .alert("Final Confirmation", isPresented: $showDeleteFinalConfirm) {
            Button("Yes, Delete My Account", role: .destructive) {
                Task {
                    await appState.deleteAccount()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This is your last chance. Tap to permanently delete your account.")
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 10) {
            AsyncImage(url: URL(string: appState.currentProfile?.avatarUrl ?? "")) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    Rectangle().fill(ClimbTheme.bgPrimary)
                }
            }
            .frame(width: 100, height: 100)
            .clipped()
            .overlay(
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(ClimbTheme.borderColor)
            )

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("Change Photo")
            }
            .buttonStyle(BrutalistSmallButtonStyle())
        }
    }

    private var supportMailURL: URL {
        URL(string: "mailto:anything@vexaiulkoo.resend.app?subject=Climb%20App%20Support") ?? URL(fileURLWithPath: "/")
    }

    private var firstNameField: some View {
        BrutalistTextField(
            label: "First Name",
            text: $firstName,
            placeholder: "Your first name",
            autocapitalization: .words,
            textContentType: .givenName
        )
    }

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Gender")
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.primaryColor)
                .textCase(.uppercase)
                .tracking(1)

            Text(genderDisplay)
                .font(ClimbTheme.bodyFont(size: 16))
                .foregroundColor(ClimbTheme.textMuted)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )

            Text("Gender cannot be changed.")
                .font(ClimbTheme.bodyFont(size: 12))
                .foregroundColor(ClimbTheme.textMuted)
        }
    }

    private var votePrefSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I want to vote on")
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.primaryColor)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(["male", "female", "everyone"], id: \.self) { pref in
                    Button(action: { votePref = pref }) {
                        Text(pref == "everyone" ? "Everyone" : (pref == "male" ? "Boys" : "Girls"))
                            .font(ClimbTheme.bodyFont(size: 14))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(votePref == pref ? ClimbTheme.primaryColor : ClimbTheme.bgSecondary)
                            .foregroundColor(ClimbTheme.textMain)
                            .overlay(
                                Rectangle()
                                    .stroke(ClimbTheme.borderColor, lineWidth: votePref == pref ? 3 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: { Task { await saveSettings() } }) {
            if isSaving {
                ProgressView().tint(.black)
            } else {
                Text("Save Changes")
            }
        }
        .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
        .disabled(isSaving)
    }

    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                appState.showToastMessage("Restoring purchases...", type: .info)
                await StoreKitManager.shared.restorePurchases()
                if StoreKitManager.shared.isGradePurchased {
                    appState.showToastMessage("Personal Grade unlocked and restored!", type: .success)
                } else if let error = StoreKitManager.shared.errorMessage {
                    appState.showToastMessage(error, type: .error)
                } else {
                    appState.showToastMessage("Purchases restored.", type: .success)
                }
            }
        }) {
            Text("Restore Purchases")
                .font(ClimbTheme.bodyFont(size: 16))
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(ClimbTheme.textMain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }

    private var contactSupportButton: some View {
        Link(destination: supportMailURL) {
            Text("Contact Support")
                .font(ClimbTheme.bodyFont(size: 16))
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundColor(ClimbTheme.textMain)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: ClimbTheme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }

    private var signOutButton: some View {
        Button("Sign Out") {
            showLogoutConfirm = true
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
    }

    private var deleteAccountSection: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(ClimbTheme.borderColor)
                .frame(height: 2)
                .padding(.vertical, 12)
                .opacity(0.3)

            Button("Delete Account") {
                showDeleteConfirm = true
            }
            .font(ClimbTheme.bodyFont(size: 14))
            .foregroundColor(ClimbTheme.errorColor)

            Text("This will permanently delete your account and all data.")
                .font(ClimbTheme.bodyFont(size: 12))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var genderDisplay: String {
        guard let gender = appState.currentProfile?.gender else { return "" }
        return gender.capitalized
    }

    private func loadCurrentValues() {
        firstName = appState.currentProfile?.firstName ?? ""
        votePref = appState.currentProfile?.votePreference ?? "everyone"
        if let stateName = appState.currentProfile?.state {
            selectedCity = CITIES.first { $0.name == stateName }
        }
    }

    private func saveSettings() async {
        guard let city = selectedCity else {
            appState.showToastMessage("Please select a region.", type: .error)
            return
        }

        isSaving = true
        do {
            try await appState.updateProfile(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                votePref: votePref,
                state: city.name,
                lat: city.lat,
                lng: city.lng
            )
            dismiss()
            await appState.loadNextMatchup()
        } catch {
            appState.showToastMessage("Failed to save settings.", type: .error)
        }
        isSaving = false
    }

    private func uploadNewPhoto(_ cropped: UIImage) async {
        guard let imageData = cropped.jpegData(compressionQuality: 0.85) else { return }

        appState.showToastMessage("Uploading photo...", type: .info)
        do {
            _ = try await appState.uploadAvatar(imageData: imageData)
            appState.showToastMessage("Profile photo updated!", type: .success)
        } catch {
            appState.showToastMessage("Failed to update photo.", type: .error)
        }
    }
}
