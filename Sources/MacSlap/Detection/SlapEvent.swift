import Foundation

struct SlapEvent {
    enum Severity: String, CaseIterable {
        case light = "Light Tap"
        case medium = "Solid Slap"
        case hard = "Full Whack"

        static func from(amplitude: Double) -> Severity {
            switch amplitude {
            case ..<0.15: return .light
            case 0.15..<0.40: return .medium
            default: return .hard
            }
        }
    }

    let timestamp: Date
    let amplitude: Double
    let severity: Severity

    init(amplitude: Double) {
        self.timestamp = Date()
        self.amplitude = amplitude
        self.severity = Severity.from(amplitude: amplitude)
    }
}

// Keep top-level alias for backward compatibility
typealias SlapSeverity = SlapEvent.Severity
