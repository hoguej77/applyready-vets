import SwiftUI
import UIKit

enum Brand {
    // An original civic palette informed by VA.gov's semantic navy and blue,
    // expressed through native Apple surfaces and typography. No government
    // seals, wordmarks, or official component styling are reproduced.
    static let ink = adaptive(light: (0.10, 0.18, 0.32), dark: (0.90, 0.94, 0.98))
    static let primary = adaptive(light: (0.00, 0.37, 0.64), dark: (0.45, 0.76, 1.00))
    static let primaryDark = adaptive(light: (0.10, 0.27, 0.50), dark: (0.58, 0.80, 1.00))
    static let primaryLighter = adaptive(light: (0.85, 0.91, 0.96), dark: (0.08, 0.20, 0.31))
    static let accentRed = adaptive(light: (0.70, 0.10, 0.13), dark: (1.00, 0.47, 0.50))
    static let secondaryText = adaptive(light: (0.27, 0.31, 0.38), dark: (0.74, 0.78, 0.84))

    // Compatibility names keep the established product screens consistent
    // while the new welcome and profile surfaces use semantic names.
    static let navy = ink
    static let navyLight = primary
    static let teal = adaptive(light: (0.00, 0.40, 0.42), dark: (0.30, 0.86, 0.83))
    static let gold = adaptive(light: (0.52, 0.33, 0.01), dark: (0.98, 0.79, 0.38))
    static let cream = adaptive(light: (0.97, 0.96, 0.95), dark: (0.08, 0.09, 0.11))
    static let success = adaptive(light: (0.08, 0.39, 0.09), dark: (0.47, 0.86, 0.43))
    static let danger = adaptive(light: (0.66, 0.07, 0.18), dark: (1.00, 0.49, 0.56))

    // Use fixed surfaces only where the component supplies a white foreground.
    static let navySurface = Color(red: 0.00, green: 0.31, blue: 0.53)
    static let successSurface = Color(red: 0.06, green: 0.38, blue: 0.11)

    private static func adaptive(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        })
    }
}

struct BrandBackground: View {
    var body: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
}

struct BrandMark: View {
    var compact = false

    var body: some View {
        Image("ApplyReadyVetsMark")
            .resizable()
            .scaledToFit()
            .frame(width: compact ? 40 : 78, height: compact ? 40 : 78)
            .clipShape(RoundedRectangle(cornerRadius: compact ? 9 : 18))
            .accessibilityLabel("ApplyReady Vets")
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
