import SwiftUI

/// Landing page — first screen users see
/// Matches the web's screen-landing
struct LandingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAuth = false
    @State private var showSafety = false

    var body: some View {
        ZStack {
            ClimbTheme.bgPrimary.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("CLIMB")
                            .font(ClimbTheme.logoFont(size: 64))
                            .foregroundColor(ClimbTheme.primaryColor)
                            .shadow(color: .black, radius: 0, x: 4, y: 4)

                        Text("Step up and make your way to the top.")
                            .font(ClimbTheme.bodyFont(size: 14))
                            .foregroundColor(ClimbTheme.textMuted)
                            .multilineTextAlignment(.center)
                    }

                    RetroIcon.ClimbLogo(size: 140)
                        .padding(.vertical, 10)

                    VStack(spacing: 12) {
                        Button("Log In / Sign Up") {
                            showAuth = true
                        }
                        .buttonStyle(BrutalistPrimaryButtonStyle(isFullWidth: true))
                    }
                }
                .brutalistCard(padding: 24)

                Spacer()
            }
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
