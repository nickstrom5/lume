import SwiftUI

@main
struct LumeApp: App {
    @State private var store = LumeStore()
    @State private var plus = PlusStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(plus)
                .preferredColorScheme(.dark)
                .task { await plus.start() }
        }
    }
}

struct RootView: View {
    @Environment(LumeStore.self) private var store

    var body: some View {
        Group {
            switch store.screen {
            case .onboarding: OnboardingView()
            case .firstScan: FirstScanView()
            case .analyzing: AnalyzingView()
            case .reveal: RevealView()
            case .paywall: PaywallView()
            case .app: AppTabs()
            }
        }
        .background(LumeTheme.bg.ignoresSafeArea())
        .tint(LumeTheme.accent)
    }
}

enum LumeTheme {
    static let bg = Color(red: 14 / 255, green: 14 / 255, blue: 12 / 255)
    static let surface = Color(red: 23 / 255, green: 23 / 255, blue: 20 / 255)
    static let surface2 = Color(red: 32 / 255, green: 31 / 255, blue: 27 / 255)
    static let fg = Color(red: 243 / 255, green: 241 / 255, blue: 236 / 255)
    static let muted = Color(red: 156 / 255, green: 152 / 255, blue: 144 / 255)
    static let subtle = Color(red: 110 / 255, green: 107 / 255, blue: 100 / 255)
    static let accent = Color(red: 232 / 255, green: 228 / 255, blue: 219 / 255)
    static let border = Color(red: 42 / 255, green: 41 / 255, blue: 37 / 255)
    static let success = Color(red: 143 / 255, green: 173 / 255, blue: 147 / 255)
}

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
