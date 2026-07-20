import Foundation

/// ELO to letter grade conversion — matches the web app exactly
func eloToGrade(_ elo: Double?) -> String {
    guard let elo = elo else { return "--" }
    let val = Int(elo.rounded())
    switch val {
    case 1600...: return "A+"
    case 1500..<1600: return "A"
    case 1400..<1500: return "A-"
    case 1300..<1400: return "B+"
    case 1200..<1300: return "B"
    case 1100..<1200: return "B-"
    case 1000..<1100: return "C+"
    case 900..<1000: return "C"
    case 800..<900: return "C-"
    case 700..<800: return "D"
    default: return "F"
    }
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
