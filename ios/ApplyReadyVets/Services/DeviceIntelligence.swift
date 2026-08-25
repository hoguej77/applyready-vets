import Foundation
import FoundationModels

struct DeviceIntelligence {
    let title: String
    let detail: String
    let systemImage: String
    let isOnDevice: Bool

    static var current: DeviceIntelligence {
        switch SystemLanguageModel.default.availability {
        case .available:
            return DeviceIntelligence(
                title: "Private on-device assistance is available",
                detail: "Eligible iPhone and iPad models can add conservative wording suggestions after the core analysis. Every suggestion is independently checked by Truth Lock.",
                systemImage: "apple.intelligence",
                isOnDevice: true
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            return fallback(
                detail: "Truth Lock is ready. Turn on Apple Intelligence in Settings to enable private on-device suggestions."
            )
        case .unavailable(.modelNotReady):
            return fallback(
                detail: "Truth Lock is ready. Apple’s on-device model is still downloading or preparing."
            )
        case .unavailable(.deviceNotEligible):
            return fallback(
                detail: "Truth Lock and secure career tools work here. This device is not eligible for Apple's on-device model."
            )
        @unknown default:
            return fallback(
                detail: "Truth Lock and secure career tools are ready. On-device AI availability could not be confirmed."
            )
        }
    }

    private static func fallback(detail: String) -> DeviceIntelligence {
        DeviceIntelligence(
            title: "Secure career engine ready",
            detail: detail,
            systemImage: "checkmark.shield.fill",
            isOnDevice: false
        )
    }
}
