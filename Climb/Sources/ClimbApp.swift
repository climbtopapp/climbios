import SwiftUI
import Supabase

@main
struct ClimbApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    // Handle deep link for magic link auth callback
                    Task {
                        do {
                            try await SupabaseManager.shared.client.auth.session(from: url)
                        } catch {
                            print("Deep link auth error: \(error)")
                        }
                    }
                }
                .task {
                    NotificationManager.shared.setupNotifications()
                    appState.listenForAuthChanges()
                    await appState.initAuth()
                }
        }
    }
}

/// Root view that switches between loading, landing, auth, register, and main app
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            ClimbTheme.bgPrimary.ignoresSafeArea()

            if appState.isLoading && appState.isAuthenticated {
                LoaderView()
            } else if !appState.isAuthenticated {
                LandingView()
            } else if !appState.isProfileComplete {
                RegisterView()
            } else {
                MainTabView()
            }

            // Toast overlay
            if appState.showToast, let message = appState.toastMessage {
                VStack {
                    ToastView(message: message, type: appState.toastType)
                        .padding(.horizontal, 24)
                        .padding(.top, 50)

                    Spacer()
                }
                .animation(.spring(response: 0.3), value: appState.showToast)
                .zIndex(2000)
            }
        }
    }
}

/// Loading spinner screen
struct LoaderView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Spinner
            Rectangle()
                .fill(Color.clear)
                .frame(width: 64, height: 64)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.bgSecondary, lineWidth: 6)
                )
                .overlay(
                    VStack {
                        Rectangle()
                            .fill(ClimbTheme.primaryColor)
                            .frame(height: 6)
                        Spacer()
                        Rectangle()
                            .fill(ClimbTheme.primaryColor)
                            .frame(height: 6)
                    }
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isAnimating)

            Text("CLIMB")
                .font(ClimbTheme.logoFont(size: 72))
                .foregroundColor(ClimbTheme.primaryColor)
                .shadow(color: .black, radius: 0, x: 4, y: 4)
                .scaleEffect(isAnimating ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isAnimating)

            Text("Loading...")
                .font(ClimbTheme.bodyFont(size: 15))
                .fontWeight(.bold)
                .foregroundColor(ClimbTheme.textMuted)
        }
        .onAppear { isAnimating = true }
    }
}
