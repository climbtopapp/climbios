import SwiftUI
import PhotosUI

/// 5-step registration wizard matching the web's screen-register
struct RegisterView: View {
    @EnvironmentObject var appState: AppState

    enum RegStep: Int, CaseIterable {
        case name = 1, region, gender, votePref, photo
    }

    @State private var currentStep: RegStep = .name
    @State private var firstName = ""
    @State private var selectedCity: City?
    @State private var selectedGender = ""
    @State private var selectedVotePref = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var croppedImageData: Data?
    @State private var previewImage: UIImage?
    @State private var showCropper = false
    @State private var rawImage: UIImage?
    @State private var isSubmitting = false
    @State private var leftRotation = Double.random(in: -2...2)
    @State private var rightRotation = Double.random(in: -2...2)

    var body: some View {
        ZStack {
            ClimbTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack {
                    switch currentStep {
                    case .name:
                        stepName
                    case .region:
                        stepRegion
                    case .gender:
                        stepGender
                    case .votePref:
                        stepVotePref
                    case .photo:
                        stepPhoto
                    }
                }
                .brutalistCard(padding: 24)
                .padding(24)
            }
        }
        .sheet(isPresented: $showCropper) {
            if let img = rawImage {
                ImageCropperView(image: img) { cropped in
                    if let data = cropped.jpegData(compressionQuality: 0.85) {
                        croppedImageData = data
                        previewImage = cropped
                    }
                    showCropper = false
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    rawImage = uiImage
                    showCropper = true
                }
            }
        }
    }

    // MARK: - Step 1: Name

    private var stepName: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(ClimbTheme.displayFont(size: 32))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text("This is how others will see you on Climb.")
                .font(ClimbTheme.bodyFont(size: 14))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)

            BrutalistTextField(
                label: "First Name",
                text: $firstName,
                placeholder: "Your first name",
                hint: "Your first name will be public."
            )

            Button("Next") {
                guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
                    appState.showToastMessage("Please enter your name.", type: .error)
                    return
                }
                withAnimation { currentStep = .region }
                randomizeRotations()
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
        }
    }

    // MARK: - Step 2: Region

    private var stepRegion: some View {
        VStack(spacing: 20) {
            Text("Where are you?")
                .font(ClimbTheme.displayFont(size: 32))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text("Select your region to compete on the Region leaderboard.")
                .font(ClimbTheme.bodyFont(size: 14))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)

            CityPickerView(selectedCity: $selectedCity)

            HStack(spacing: 10) {
                Button("Back") {
                    withAnimation { currentStep = .name }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("Next") {
                    guard selectedCity != nil else {
                        appState.showToastMessage("Please select your region.", type: .error)
                        return
                    }
                    withAnimation { currentStep = .gender }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Step 3: Gender

    private var stepGender: some View {
        VStack(spacing: 20) {
            Text("Are you a:")
                .font(ClimbTheme.displayFont(size: 32))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text("This cannot be changed later.")
                .font(ClimbTheme.bodyFont(size: 14))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 1, green: 0.667, blue: 0)) // #ffaa00
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: { selectedGender = "male" }) {
                    MashSelectionCard(
                        title: "Boy",
                        icon: AnyView(RetroIcon.MaleIcon(size: 48)),
                        isSelected: selectedGender == "male",
                        rotation: leftRotation
                    )
                }
                .buttonStyle(.plain)

                OrDivider()

                Button(action: { selectedGender = "female" }) {
                    MashSelectionCard(
                        title: "Girl",
                        icon: AnyView(RetroIcon.FemaleIcon(size: 48)),
                        isSelected: selectedGender == "female",
                        rotation: rightRotation
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button("Back") {
                    withAnimation { currentStep = .region }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("Next") {
                    guard !selectedGender.isEmpty else {
                        appState.showToastMessage("Please select your gender.", type: .error)
                        return
                    }
                    withAnimation { currentStep = .votePref }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(selectedGender.isEmpty)
            }
        }
    }

    // MARK: - Step 4: Vote Preference

    private var stepVotePref: some View {
        VStack(spacing: 20) {
            Text("Do you want to vote on:")
                .font(ClimbTheme.displayFont(size: 32))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text("You can change this later in Settings.")
                .font(ClimbTheme.bodyFont(size: 14))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(action: { selectedVotePref = "male" }) {
                    MashSelectionCard(
                        title: "Boys",
                        icon: AnyView(RetroIcon.MaleIcon(size: 48)),
                        isSelected: selectedVotePref == "male",
                        rotation: leftRotation
                    )
                }
                .buttonStyle(.plain)

                OrDivider()

                Button(action: { selectedVotePref = "female" }) {
                    MashSelectionCard(
                        title: "Girls",
                        icon: AnyView(RetroIcon.FemaleIcon(size: 48)),
                        isSelected: selectedVotePref == "female",
                        rotation: rightRotation
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button("Back") {
                    withAnimation { currentStep = .gender }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("Next") {
                    guard !selectedVotePref.isEmpty else {
                        appState.showToastMessage("Please select who you want to vote on.", type: .error)
                        return
                    }
                    withAnimation { currentStep = .photo }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(selectedVotePref.isEmpty)
            }
        }
    }

    // MARK: - Step 5: Photo Upload

    private var stepPhoto: some View {
        VStack(spacing: 20) {
            Text("Add a Photo")
                .font(ClimbTheme.displayFont(size: 32))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)

            Text("Upload a clear photo of your face. It will be public and shown to other players for voting.")
                .font(ClimbTheme.bodyFont(size: 14))
                .foregroundColor(ClimbTheme.textMuted)
                .multilineTextAlignment(.center)

            // Preview
            ZStack {
                if let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipped()
                } else {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(ClimbTheme.primaryColor)
                }
            }
            .frame(width: 150, height: 150)
            .background(ClimbTheme.bgSecondary)
            .overlay(
                Rectangle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(ClimbTheme.borderColor)
            )

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("Choose Photo")
            }
            .buttonStyle(BrutalistSecondaryButtonStyle())

            Text("Your photo will be cropped and compressed.")
                .font(ClimbTheme.bodyFont(size: 12))
                .foregroundColor(ClimbTheme.textMuted)

            Text("Required: A photo of your face. It will be public and voted on by others.")
                .font(ClimbTheme.bodyFont(size: 12))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.errorColor)

            HStack(spacing: 10) {
                Button("Back") {
                    withAnimation { currentStep = .votePref }
                    randomizeRotations()
                }
                .buttonStyle(BrutalistSecondaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button(action: { Task { await submitRegistration() } }) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Start Climbing")
                    }
                }
                .buttonStyle(BrutalistPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(croppedImageData == nil || isSubmitting)
            }
        }
    }

    // MARK: - Actions

    private func submitRegistration() async {
        guard let imageData = croppedImageData,
              let city = selectedCity else { return }

        let name = firstName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !selectedGender.isEmpty, !selectedVotePref.isEmpty else { return }

        isSubmitting = true
        do {
            try await appState.completeRegistration(
                firstName: name,
                gender: selectedGender,
                votePref: selectedVotePref,
                state: city.name,
                lat: city.lat,
                lng: city.lng,
                imageData: imageData
            )
            appState.showToastMessage("Profile ready! Welcome to Climb.", type: .success)
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
        isSubmitting = false
    }

    private func randomizeRotations() {
        leftRotation = Double.random(in: -2...2)
        rightRotation = Double.random(in: -2...2)
    }
}
