import Foundation

/// ELO to grade conversion (scale out of 100) — matches the web app exactly
func eloToGrade(_ elo: Double?) -> String {
    guard let elo = elo else { return "--" }
    let val = elo
    let score = min(100, max(1, Int((80.0 + (val - 1200.0) * 0.04).rounded())))
    return "\(score)/100"
}

/// Mask email for display: ab•••@domain.com
func maskEmail(_ email: String?) -> String {
    guard let email = email, !email.isEmpty else { return "Anonymous Climber" }
    let parts = email.split(separator: "@")
    if parts.count == 2 {
        let name = String(parts[0])
        let domain = String(parts[1])
        if name.count > 2 {
            return String(name.prefix(2)) + "•••@" + domain
        }
        return "•••@" + domain
    }
    return "Climber"
}
