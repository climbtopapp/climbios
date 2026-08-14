import SwiftUI

/// Landing page — first screen users see
/// Matches the web's screen-landing
struct LandingView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAuth = false
    @State private var showSafety = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ClimbTheme.bgPrimary.ignoresSafeArea()

            // Safety Info Button in top left
            Button(action: { showSafety = true }) {
                Text("?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ClimbTheme.textMuted)
                    .frame(width: 36, height: 36)
                    .background(ClimbTheme.bgSecondary)
                    .overlay(
                        Rectangle()
                            .stroke(ClimbTheme.borderColor, lineWidth: 2)
                    )
            }
            .padding(.top, 50)
            .padding(.leading, 24)
            .zIndex(10)

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
        .sheet(isPresented: $showSafety) {
            SafetyInfoView()
        }
        .fullScreenCover(isPresented: $showAuth) {
            AuthView()
                .environmentObject(appState)
        }
    }
}
