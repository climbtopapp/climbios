import SwiftUI

/// Landing page — first screen users see
/// Matches the web's screen-landing
struct LandingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAuth = false
    @State private var showSafety = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Spacer().frame(height: 20)

                    Text("CLIMB")
                        .font(ClimbTheme.logoFont(size: 72))
                        .foregroundColor(ClimbTheme.primaryColor)
                        .shadow(color: .black, radius: 0, x: 4, y: 4)

                    Text("Step up and make your way to the top.")
                        .font(ClimbTheme.bodyFont(size: 15))
                        .foregroundColor(ClimbTheme.textMuted)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Logo
                RetroIcon.ClimbLogo(size: 160)
                    .padding(.vertical, 25)

                Spacer()

                VStack(spacing: 12) {
                    // Log In / Sign Up
                    Button("Log In / Sign Up") {
                        showAuth = true
                    }
                    .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                }
                .padding(.bottom, 20)
            }
            .padding(24)
            .brutalistCard(padding: 0)
            .padding(24)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ClimbTheme.bgPrimary)
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
                .environmentObject(appState)
        }
    }
}
