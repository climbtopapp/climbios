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
                    if filteredNotifications.isEmpty {
                        VStack(spacing: 12) {
                            Text("No notifications yet!")
                                .font(ClimbTheme.bodyFont(size: 14))
                                .foregroundColor(ClimbTheme.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotifications) { item in
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

    private var filteredNotifications: [NotificationItem] {
        appState.notifications
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notificationIcon(for: item.title))
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(ClimbTheme.primaryColor)
                .frame(width: 36, height: 36)
                .background(ClimbTheme.bgPrimary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.title)
                        .font(ClimbTheme.displayFont(size: 15))
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
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isNewNotification(item.createdAt) ? ClimbTheme.primaryLight : ClimbTheme.bgSecondary)
        .overlay(
            Rectangle()
                .stroke(ClimbTheme.borderColor, lineWidth: 2)
        )
    }

    private func notificationIcon(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("star") || lower.contains("view") || lower.contains("instagram") { return "star.fill" }
        if lower.contains("club") { return "person.3.fill" }
        if lower.contains("rank") || lower.contains("top") { return "trophy.fill" }
        if lower.contains("welcome") || lower.contains("match") { return "sparkles" }
        return "bell.fill"
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
