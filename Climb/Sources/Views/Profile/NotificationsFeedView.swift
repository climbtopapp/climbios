import SwiftUI

/// Notifications modal sheet for iOS
struct NotificationsFeedView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // List
                ScrollView {
                    if appState.notifications.isEmpty {
                        VStack(spacing: 12) {
                            Text("No notifications yet!")
                                .font(ClimbTheme.bodyFont(size: 14))
                                .foregroundColor(ClimbTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(appState.notifications) { item in
                                notificationRow(item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .background(ClimbTheme.bgPrimary)
            .navigationTitle("Notifications")
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
            .task {
                await appState.fetchNotifications()
            }
        }
    }

    private func isNewNotification(_ createdAt: String) -> Bool {
        let lastRead = UserDefaults.standard.double(forKey: "climb_last_read_notifications")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: createdAt)
        if date == nil {
            let fallback = ISO8601DateFormatter()
            date = fallback.date(from: createdAt)
        }
        guard let date = date else { return false }
        // Offset by 1 second so notifications just opened are not instantly marked old while looking at them
        return date.timeIntervalSince1970 > (lastRead - 1.0)
    }

    private func notificationRow(_ item: NotificationItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(item.title)
                    .font(ClimbTheme.displayFont(size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(ClimbTheme.textMain)

                Spacer()

                Text(formatDate(item.createdAt))
                    .font(ClimbTheme.bodyFont(size: 11))
                    .foregroundColor(ClimbTheme.textMuted)
            }

            Text(item.message)
                .font(ClimbTheme.bodyFont(size: 13))
                .foregroundColor(ClimbTheme.textMain)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isNewNotification(item.createdAt) ? ClimbTheme.primaryLight : ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: 2)
        )
    }

    private func formatDate(_ isoString: String) -> String {
        // Parse ISO 8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = formatter.date(from: isoString)
        if date == nil {
            // Try fallback without fractional seconds
            let fallbackFormatter = ISO8601DateFormatter()
            date = fallbackFormatter.date(from: isoString)
        }
        
        guard let date = date else { return "" }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .short
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
}
