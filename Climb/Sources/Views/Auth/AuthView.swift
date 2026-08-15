import SwiftUI

/// Authentication flow — sign up / log in with magic link
/// Matches the web's screen-auth with 3 steps
struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    enum AuthStep {
        case welcome, email, otp
    }

    @State private var step: AuthStep = .welcome
    @State private var email = ""
    @State private var verificationCode = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var leftRotation = Double.random(in: -2...2)
    @State private var rightRotation = Double.random(in: -2...2)

    var body: some View {
        ZStack {
            ClimbTheme.bgPrimary.ignoresSafeArea()

            VStack {
                Spacer()

                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 4) {
                            Text("CLIMB")
                                .font(ClimbTheme.logoFont(size: 64))
                                .foregroundColor(ClimbTheme.primaryColor)
                                .shadow(color: .black, radius: 0, x: 4, y: 4)

                            Text("Step up and make your way to the top.")
                                .font(ClimbTheme.bodyFont(size: 14))
                                .foregroundColor(ClimbTheme.textMuted)
                        }

                        switch step {
                        case .welcome:
                            welcomeStep
                        case .email:
                            emailStep
                        case .otp:
                            otpStep
                        }
                    }
                    .padding(24)

                    // Exit / Close button in top right
                    Button(action: { dismiss() }) {
                        Text("✕")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(ClimbTheme.textMuted)
                            .frame(width: 32, height: 32)
                            .background(ClimbTheme.bgPrimary)
                            .overlay(
                                Rectangle()
                                    .stroke(ClimbTheme.borderColor, lineWidth: 2)
                            )
                    }
                    .padding(12)
                }
                .brutalistCard(padding: 0)

                Spacer()
            }
            .padding(24)
        }
    }

    // MARK: - Welcome Step (Sign Up or Log In)

    private var welcomeStep: some View {
        VStack(spacing: 12) {
            // Sign Up card
            Button(action: {
                isSignUp = true
                step = .email
            }) {
                MashSelectionCard(
                    title: "Sign Up",
                    icon: AnyView(
                        Image(systemName: "triangle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    ),
                    isSelected: false,
                    rotation: leftRotation
                )
            }
            .buttonStyle(.plain)

            OrDivider()

            // Log In card
            Button(action: {
                isSignUp = false
                step = .email
            }) {
                MashSelectionCard(
                    title: "Log In",
                    icon: AnyView(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                    ),
                    isSelected: false,
                    rotation: rightRotation
                )
            }
            .buttonStyle(.plain)

            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(BrutalistTextButtonStyle())
            .padding(.top, 15)

            VStack(spacing: 2) {
                Text("By signing up, you agree to the standard Apple")
                    .font(ClimbTheme.bodyFont(size: 10))
                    .foregroundColor(ClimbTheme.textMuted)
                Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    .font(ClimbTheme.bodyFont(size: 10))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.accentColor)
                    .underline()
            }
            .padding(.top, 10)
        }
    }

    // MARK: - Email Step

    private var emailStep: some View {
        VStack(spacing: 20) {
            BrutalistTextField(
                label: isSignUp ? "Create Account Email" : "Email Address",
                text: $email,
                placeholder: "you@example.com",
                hint: isSignUp ? "Enter your email to create a new account." : "Enter your email to log into your account.",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            Button(action: { Task { await sendLink() } }) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(isSignUp ? "Send Sign Up Link" : "Send Login Link")
                }
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
            .disabled(email.isEmpty || isLoading)

            Button("Go Back") {
                step = .welcome
            }
            .buttonStyle(BrutalistTextButtonStyle())
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Verification Code Entry Step

    private var otpStep: some View {
        VStack(spacing: 20) {
            BrutalistTextField(
                label: "Enter 6-Digit Code",
                text: $verificationCode,
                placeholder: "123456",
                hint: "Check your inbox (and spam folder) for the verification code.",
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )

            Button(action: { Task { await verifyCode() } }) {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Verify Code")
                }
            }
            .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
            .disabled(verificationCode.count != 6 || isLoading)

            Button("Go Back") {
                step = .email
            }
            .buttonStyle(BrutalistTextButtonStyle())
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Actions

    private func isReviewerEmail(_ email: String) -> Bool {
        let lower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower == "reviewer@apple.com"
    }

    private func sendLink() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty else { return }

        isLoading = true
        if isReviewerEmail(trimmedEmail) {
            try? await Task.sleep(nanoseconds: 400_000_000) // Small mock network delay
            appState.showToastMessage("Verification code sent to your email! (Reviewer Demo Mode)", type: .success)
            step = .otp
            isLoading = false
            return
        }

        // Check account existence for Log In vs Sign Up
        let isRegistered = await appState.isEmailRegistered(email: trimmedEmail)

        if !isSignUp && !isRegistered {
            // User pressed Log In but no account exists with this email
            appState.showToastMessage("No account found for this email. Please Sign Up to create an account.", type: .error)
            isLoading = false
            return
        }

        if isSignUp && isRegistered {
            // User pressed Sign Up but already has an account
            appState.showToastMessage("Account found! Sending login code...", type: .info)
        }

        do {
            try await appState.sendMagicLink(email: trimmedEmail)
            appState.showToastMessage("Verification code sent to your email!", type: .success)
            step = .otp
        } catch {
            appState.showToastMessage(error.localizedDescription, type: .error)
        }
        isLoading = false
    }

    private func verifyCode() async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedCode = verificationCode.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty && trimmedCode.count == 6 else { return }

        isLoading = true
        if isReviewerEmail(trimmedEmail) {
            try? await Task.sleep(nanoseconds: 400_000_000)
            if trimmedCode == "123456" {
                appState.loginAsDemoUser(email: trimmedEmail)
                appState.showToastMessage("Successfully authenticated!", type: .success)
                dismiss()
            } else {
                appState.showToastMessage("Invalid verification code. Please check your code and try again.", type: .error)
            }
            isLoading = false
            return
        }

        do {
            try await appState.verifyOTP(email: trimmedEmail, token: trimmedCode)
            appState.showToastMessage("Successfully authenticated!", type: .success)
            dismiss()
        } catch {
            print("Verify OTP failed: \(error)")
            appState.showToastMessage("Invalid verification code. Please check your code and try again.", type: .error)
        }
        isLoading = false
    }

}
