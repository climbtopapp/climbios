import SwiftUI
import Supabase
import Combine

/// Profile model matching the Supabase `profiles` table
struct Profile: Codable, Identifiable {
    let id: UUID
    var email: String?
    var firstName: String?
    var gender: String?
    var votePreference: String?
    var avatarUrl: String?
    var latitude: Double?
    var longitude: Double?
    var state: String?
    var elo: Double?
    var votesCast: Int
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, gender, latitude, longitude, state, elo
        case firstName = "first_name"
        case votePreference = "vote_preference"
        case avatarUrl = "avatar_url"
        case votesCast = "votes_cast"
        case createdAt = "created_at"
    }
}

/// Matchup profile returned from get_matchup RPC
struct MatchupProfile: Codable, Identifiable {
    let id: UUID
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case avatarUrl = "avatar_url"
    }
}

/// Leaderboard row returned from get_leaderboard_data RPC
struct LeaderboardRow: Codable, Identifiable {
    var id: UUID { userId }
    let userId: UUID
    let firstName: String?
    let avatarUrl: String?
    let state: String?
    let relativeRank: Int?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case avatarUrl = "avatar_url"
        case state
        case relativeRank = "relative_rank"
    }
}

/// User rank stats returned from get_user_ranks RPC
struct UserRankStats: Codable {
    let globalRank: Int?
    let totalGlobal: Int?
    let stateRank: Int?
    let totalState: Int?

    enum CodingKeys: String, CodingKey {
        case globalRank = "global_rank"
        case totalGlobal = "total_global"
        case stateRank = "state_rank"
        case totalState = "total_state"
    }
}

/// Club info model
struct ClubInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let code: String
    let createdBy: UUID
    let memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, code
        case createdBy = "created_by"
        case memberCount = "member_count"
    }
}

/// Club member model
struct ClubMember: Codable, Identifiable {
    var id: UUID { userId }
    let userId: UUID
    let firstName: String?
    let avatarUrl: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case firstName = "first_name"
        case avatarUrl = "avatar_url"
        case state
    }
}

/// Response from get_my_club RPC
struct ClubResponse: Codable {
    let club: ClubInfo?
    let members: [ClubMember]?
}

/// Notification model matching Supabase `notifications` table
struct NotificationItem: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let title: String
    let message: String
    let type: String
    var isRead: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, message, type
        case userId = "user_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

/// Observable app state shared across the app
@MainActor
final class AppState: ObservableObject {
    // Auth
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isLoading = true
    @Published var isAuthenticated = false

    var isDemoUser: Bool {
        currentUser?.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    }

    func loginAsDemoUser(email: String) {
        let demoUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        let demoUser = User(
            id: demoUUID,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            email: email,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let demoProfile = Profile(
            id: demoUUID,
            email: email,
            firstName: "Apple Reviewer",
            gender: "everyone",
            votePreference: "everyone",
            avatarUrl: "https://example.com/demo-avatar.jpg",
            latitude: 37.7749,
            longitude: -122.4194,
            state: "CA",
            elo: 1500.0,
            votesCast: 9999,
            createdAt: "2026-07-20T00:00:00Z"
        )
        
        self.currentUser = demoUser
        self.currentProfile = demoProfile
        self.isAuthenticated = true
        self.isLoading = false
    }

    // Navigation
    @Published var selectedTab: AppTab = .mash
    @Published var showSettings = false
    @Published var showSafetyInfo = false

    // Mash
    @Published var currentMatchup: [MatchupProfile] = []
    @Published var isMashClubMode = false

    // Leaderboard
    @Published var currentLeaderboardTab: LeaderboardTab = .global
    @Published var currentLeaderboardGender: String = "everyone"

    // Clubs
    @Published var currentClubInfo: ClubInfo?
    @Published var currentClubMembers: [ClubMember] = []

    // User preferences
    @Published var userVotePreference: String = "everyone"
    @Published var userState: String = ""
    @Published var userLatitude: Double = 0
    @Published var userLongitude: Double = 0

    // Toast
    @Published var toastMessage: String?
    @Published var toastType: ToastType = .info
    @Published var showToast = false

    // Notifications
    @Published var notifications: [NotificationItem] = []

    private let supabase = SupabaseManager.shared.client

    enum AppTab: String, CaseIterable {
        case mash, leaderboard, challenges, clubs, profile
    }

    enum LeaderboardTab: String {
        case global, state, club
    }

    enum ToastType {
        case success, error, info
    }

    // MARK: - Toast

    func showToastMessage(_ message: String, type: ToastType = .info) {
        toastMessage = message
        toastType = type
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            showToast = false
        }
    }

    // MARK: - Auth

    func initAuth() async {
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await fetchUserProfile()
        } catch {
            currentUser = nil
            isAuthenticated = false
            isLoading = false
        }
    }

    func listenForAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                print("Auth state event: \(event)")
                await MainActor.run {
                    if let user = session?.user {
                        self.currentUser = user
                        self.isAuthenticated = true
                    } else {
                        self.currentUser = nil
                        self.currentProfile = nil
                        self.isAuthenticated = false
                        self.isLoading = false
                    }
                }
                if session?.user != nil {
                    await fetchUserProfile()
                }
            }
        }
    }

    func sendMagicLink(email: String) async throws {
        try await supabase.auth.signInWithOTP(
            email: email
        )
    }

    func verifyOTP(email: String, token: String) async throws {
        try await supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
    }


    func signOut() async {
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
            currentClubInfo = nil
            currentClubMembers = []
        } catch {
            showToastMessage("Failed to sign out.", type: .error)
        }
    }

    func deleteAccount() async {
        do {
            try await supabase.rpc("delete_own_account").execute()
            showToastMessage("Account deleted. Goodbye.", type: .success)
            await signOut()
        } catch {
            showToastMessage("Failed to delete account: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - Profile

    func fetchUserProfile() async {
        guard let userId = currentUser?.id else { return }
        if isDemoUser {
            await MainActor.run {
                self.isLoading = false
            }
            return
        }

        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            await MainActor.run {
                self.currentProfile = profile
                self.userLatitude = profile.latitude ?? 0
                self.userLongitude = profile.longitude ?? 0
                self.userState = profile.state ?? "Unknown State"
                self.userVotePreference = profile.votePreference ?? "everyone"
                self.isLoading = false
            }

            // Fetch club info
            await fetchClubInfo()
            // Fetch notifications
            await fetchNotifications()
        } catch {
            print("Profile not found, retrying... \(error)")
            try? await Task.sleep(for: .seconds(1))
            await fetchUserProfile()
        }
    }

    var isProfileComplete: Bool {
        if isDemoUser { return true }
        guard let p = currentProfile else { return false }
        return p.avatarUrl != nil && p.firstName != nil && p.gender != nil
            && !p.avatarUrl!.isEmpty && !p.firstName!.isEmpty && !p.gender!.isEmpty
    }

    func fetchNotifications() async {
        guard let userId = currentUser?.id else { return }
        if isDemoUser { return }
        do {
            let fetched: [NotificationItem] = try await supabase
                .from("notifications")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            await MainActor.run {
                self.notifications = fetched
            }
        } catch {
            print("Failed to fetch notifications: \(error)")
        }
    }

    func markAllNotificationsAsRead() async {
        guard let userId = currentUser?.id else { return }
        if isDemoUser { return }
        let unreadIds = notifications.filter { !$0.isRead }.map { $0.id.uuidString }
        if unreadIds.isEmpty { return }
        
        do {
            try await supabase
                .from("notifications")
                .update(["is_read": true])
                .in("id", values: unreadIds)
                .execute()
            
            await MainActor.run {
                for i in 0..<self.notifications.count {
                    if unreadIds.contains(self.notifications[i].id.uuidString) {
                        self.notifications[i].isRead = true
                    }
                }
            }
        } catch {
            print("Failed to mark notifications as read: \(error)")
        }
    }

    func updateProfile(firstName: String, votePref: String, state: String, lat: Double, lng: Double) async throws {
        guard let userId = currentUser?.id else { return }
        if isDemoUser {
            currentProfile?.firstName = firstName
            currentProfile?.votePreference = votePref
            currentProfile?.state = state
            currentProfile?.latitude = lat
            currentProfile?.longitude = lng
            userState = state
            userVotePreference = votePref
            userLatitude = lat
            userLongitude = lng
            return
        }

        try await supabase
            .from("profiles")
            .update([
                "first_name": firstName,
                "vote_preference": votePref,
                "state": state,
                "latitude": String(lat),
                "longitude": String(lng)
            ])
            .eq("id", value: userId.uuidString)
            .execute()

        currentProfile?.firstName = firstName
        currentProfile?.votePreference = votePref
        currentProfile?.state = state
        currentProfile?.latitude = lat
        currentProfile?.longitude = lng
        userState = state
        userVotePreference = votePref
        userLatitude = lat
        userLongitude = lng
    }

    func uploadAvatar(imageData: Data) async throws -> String {
        guard let userId = currentUser?.id else { throw NSError(domain: "", code: 0) }
        if isDemoUser {
            let urlString = "https://example.com/demo-avatar.jpg"
            currentProfile?.avatarUrl = urlString
            return urlString
        }

        let fileName = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let filePath = "\(userId.uuidString)/\(fileName)"

        try await supabase.storage
            .from("avatars")
            .upload(filePath, data: imageData, options: .init(cacheControl: "604800", contentType: "image/jpeg"))

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: filePath)

        let urlString = publicURL.absoluteString

        try await supabase
            .from("profiles")
            .update(["avatar_url": urlString])
            .eq("id", value: userId.uuidString)
            .execute()

        currentProfile?.avatarUrl = urlString
        return urlString
    }

    func completeRegistration(firstName: String, gender: String, votePref: String, state: String, lat: Double, lng: Double, imageData: Data) async throws {
        guard let userId = currentUser?.id else { throw NSError(domain: "", code: 0) }
        if isDemoUser {
            userState = state
            userVotePreference = votePref
            userLatitude = lat
            userLongitude = lng
            return
        }

        // 1. Upload avatar
        let fileName = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let filePath = "\(userId.uuidString)/\(fileName)"

        try await supabase.storage
            .from("avatars")
            .upload(filePath, data: imageData, options: .init(contentType: "image/jpeg"))

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: filePath)

        let urlString = publicURL.absoluteString

        // 2. Update profile
        try await supabase
            .from("profiles")
            .update([
                "avatar_url": urlString,
                "first_name": firstName,
                "gender": gender,
                "vote_preference": votePref,
                "state": state,
                "latitude": String(lat),
                "longitude": String(lng)
            ])
            .eq("id", value: userId.uuidString)
            .execute()

        userState = state
        userVotePreference = votePref
        userLatitude = lat
        userLongitude = lng

        await fetchUserProfile()
    }

    // MARK: - Matchup / Voting

    func loadNextMatchup() async {
        guard currentUser != nil else { return }

        do {
            if isMashClubMode, let clubId = currentClubInfo?.id {
                let data: [MatchupProfile] = try await supabase
                    .rpc("get_matchup_club", params: [
                        "voter_id": currentUser!.id.uuidString,
                        "pref": userVotePreference,
                        "filter_club_id": clubId.uuidString
                    ])
                    .execute()
                    .value
                currentMatchup = data
            } else {
                let data: [MatchupProfile] = try await supabase
                    .rpc("get_matchup", params: [
                        "voter_id": currentUser!.id.uuidString,
                        "pref": userVotePreference
                    ])
                    .execute()
                    .value
                currentMatchup = data
            }

            // Prefetch photos for instant rendering
            for profile in currentMatchup {
                if let avatarUrl = profile.avatarUrl {
                    ImageCacheManager.shared.prefetch(urlString: avatarUrl)
                }
            }
        } catch {
            print("Failed to load matchup: \(error)")
            showToastMessage("Failed to load matchup.", type: .error)
        }
    }

    func castVote(winnerId: UUID, loserId: UUID) async {
        if isDemoUser {
            if var profile = currentProfile {
                profile.votesCast += 1
                currentProfile = profile
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            return
        }
        do {
            try await supabase.rpc("cast_vote", params: [
                "winner_id": winnerId.uuidString,
                "loser_id": loserId.uuidString
            ]).execute()

            if var profile = currentProfile {
                profile.votesCast += 1
                currentProfile = profile
            }

            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

        } catch {
            print("Failed to cast vote: \(error)")
            showToastMessage("Could not register vote.", type: .error)
        }
    }

    func blockUser(blockedId: UUID) async {
            guard let userId = currentUser?.id else { return }
            if isDemoUser {
                showToastMessage("User blocked.", type: .success)
                return
            }

        do {
            try await supabase
                .from("blocks")
                .insert([
                    "blocker_id": userId.uuidString,
                    "blocked_id": blockedId.uuidString
                ])
                .execute()

            showToastMessage("User blocked and reported.", type: .success)
        } catch {
            showToastMessage("User blocked.", type: .success)
        }
    }

    // MARK: - Leaderboard

    func loadLeaderboard() async -> [LeaderboardRow] {
        guard currentUser != nil else { return [] }
        if isDemoUser {
            return [
                LeaderboardRow(userId: UUID(), firstName: "Apple Reviewer", avatarUrl: nil, state: "CA", relativeRank: 1),
                LeaderboardRow(userId: UUID(), firstName: "Sarah", avatarUrl: nil, state: "NY", relativeRank: 2),
                LeaderboardRow(userId: UUID(), firstName: "Alex", avatarUrl: nil, state: "MI", relativeRank: 3),
                LeaderboardRow(userId: UUID(), firstName: "David", avatarUrl: nil, state: "TX", relativeRank: 4),
                LeaderboardRow(userId: UUID(), firstName: "Jessica", avatarUrl: nil, state: "FL", relativeRank: 5)
            ]
        }

        do {
            if currentLeaderboardTab == .club {
                guard let clubId = currentClubInfo?.id else { return [] }
                let data: [LeaderboardRow] = try await supabase
                    .rpc("get_club_leaderboard", params: [
                        "target_club_id": clubId.uuidString,
                        "gender_filter": currentLeaderboardGender
                    ])
                    .execute()
                    .value
                return data
            } else {
                let data: [LeaderboardRow] = try await supabase
                    .rpc("get_leaderboard_data", params: [
                        "viewer_id": currentUser!.id.uuidString,
                        "viewer_lat": String(userLatitude),
                        "viewer_lon": String(userLongitude),
                        "viewer_state": userState,
                        "lb_type": currentLeaderboardTab.rawValue,
                        "gender_filter": currentLeaderboardGender
                    ])
                    .execute()
                    .value
                return data
            }
        } catch {
            print("Failed to load leaderboard: \(error)")
            showToastMessage("Failed to load rankings.", type: .error)
            return []
        }
    }

    func loadUserRanks() async -> UserRankStats? {
        guard let userId = currentUser?.id else { return nil }
        if isDemoUser {
            return UserRankStats(globalRank: 1, totalGlobal: 100, stateRank: 1, totalState: 10)
        }

        do {
            let data: [UserRankStats] = try await supabase
                .rpc("get_user_ranks", params: [
                    "user_id_param": userId.uuidString,
                    "viewer_lat": String(userLatitude),
                    "viewer_lon": String(userLongitude),
                    "viewer_state": userState
                ])
                .execute()
                .value
            return data.first
        } catch {
            print("Failed to load user ranks: \(error)")
            return nil
        }
    }

    // MARK: - Clubs

    func fetchClubInfo() async {
        if isDemoUser {
            currentClubInfo = ClubInfo(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: "Reviewer Club",
                code: "REVIEW",
                createdBy: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                memberCount: 3
            )
            currentClubMembers = [
                ClubMember(userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, firstName: "Apple Reviewer", avatarUrl: nil, state: "CA"),
                ClubMember(userId: UUID(), firstName: "Sarah", avatarUrl: nil, state: "NY"),
                ClubMember(userId: UUID(), firstName: "Alex", avatarUrl: nil, state: "MI")
            ]
            return
        }
        do {
            let data: ClubResponse = try await supabase
                .rpc("get_my_club")
                .execute()
                .value
            currentClubInfo = data.club
            currentClubMembers = data.members ?? []
        } catch {
            currentClubInfo = nil
            currentClubMembers = []
        }
    }

    func createClub(name: String) async throws {
        if isDemoUser {
            currentClubInfo = ClubInfo(
                id: UUID(),
                name: name,
                code: "NEWCLB",
                createdBy: currentUser!.id,
                memberCount: 1
            )
            currentClubMembers = [
                ClubMember(userId: currentUser!.id, firstName: "Apple Reviewer", avatarUrl: nil, state: "CA")
            ]
            return
        }
        try await supabase.rpc("create_club", params: ["club_name": name]).execute()
        await fetchClubInfo()
    }

    func joinClub(code: String) async throws {
        if isDemoUser {
            currentClubInfo = ClubInfo(
                id: UUID(),
                name: "Joined Demo Club",
                code: code.uppercased(),
                createdBy: UUID(),
                memberCount: 2
            )
            currentClubMembers = [
                ClubMember(userId: currentUser!.id, firstName: "Apple Reviewer", avatarUrl: nil, state: "CA"),
                ClubMember(userId: UUID(), firstName: "John", avatarUrl: nil, state: "CA")
            ]
            return
        }
        try await supabase.rpc("join_club", params: ["invite_code": code]).execute()
        await fetchClubInfo()
    }

    func leaveClub() async throws {
        if isDemoUser {
            currentClubInfo = nil
            currentClubMembers = []
            isMashClubMode = false
            return
        }
        try await supabase.rpc("leave_club").execute()
        currentClubInfo = nil
        currentClubMembers = []
        isMashClubMode = false
    }

    func updateClubName(_ newName: String) async throws {
        if isDemoUser {
            currentClubInfo = ClubInfo(
                id: currentClubInfo!.id,
                name: newName,
                code: currentClubInfo!.code,
                createdBy: currentClubInfo!.createdBy,
                memberCount: currentClubInfo?.memberCount
            )
            return
        }
        try await supabase.rpc("update_club_name", params: ["new_name": newName]).execute()
        currentClubInfo = ClubInfo(
            id: currentClubInfo!.id,
            name: newName,
            code: currentClubInfo!.code,
            createdBy: currentClubInfo!.createdBy,
            memberCount: currentClubInfo?.memberCount
        )
    }

    func removeClubMember(userId: UUID) async throws {
        if isDemoUser {
            currentClubMembers.removeAll { $0.userId == userId }
            return
        }
        try await supabase.rpc("remove_club_member", params: ["target_user_id": userId.uuidString]).execute()
        await fetchClubInfo()
    }
}
