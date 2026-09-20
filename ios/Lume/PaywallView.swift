import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(LumeStore.self) private var store
    @Environment(PlusStore.self) private var plus
    @State private var plan: PlusProduct = .yearly

    var body: some View {
        DuoLayout {
            FacePane(
                image: store.pendingScan.flatMap { store.thumb(for: $0.thumbName) } ?? UIImage(named: "still"),
                caption: "The download isn’t the sale."
            )
        } secondary: {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Wordmark()
                        Kicker(text: "Lume Plus")
                        Text("Unlock your ritual")
                            .font(.display(32))
                            .foregroundStyle(LumeTheme.fg)
                        Text("Seven days free. Cancel before it renews and you keep the first reading.")
                            .font(.system(size: 15))
                            .foregroundStyle(LumeTheme.muted)

                        VStack(alignment: .leading, spacing: 8) {
                            perk("Full glow map after every scan")
                            perk("A sixty-second AM and PM built around your face")
                            perk("Daily scans, streaks, and a fourteen-day trend")
                            perk("Photos stay on this device")
                        }
                        .padding(.vertical, 8)

                        planCard(.yearly, title: "Year", price: plus.yearly?.displayPrice ?? "$39.99", note: "Best value · 7-day trial")
                        planCard(.weekly, title: "Week", price: plus.weekly?.displayPrice ?? "$7.99", note: "7-day trial")

                        if let error = plus.error {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(red: 196 / 255, green: 132 / 255, blue: 122 / 255))
                        }

                        Text("Payment is charged to your Apple ID. The plan renews unless you cancel at least 24 hours before the period ends. Not a medical device.")
                            .font(.system(size: 12))
                            .foregroundStyle(LumeTheme.subtle)
                            .padding(.top, 4)
                    }
                    .padding(20)
                }

                VStack(spacing: 10) {
                    LumeButton(title: plus.isBusy ? "Working…" : "Start 7-day trial") {
                        Task { await buy() }
                    }
                    .disabled(plus.isBusy)
                    Button("Restore purchases") {
                        Task {
                            await plus.restore()
                            if plus.isPlus { store.startTrial() }
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LumeTheme.muted)
                }
                .padding(20)
            }
            .background(LumeTheme.bg)
        }
    }

    private func perk(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("✓").foregroundStyle(LumeTheme.success)
            Text(text).font(.system(size: 15)).foregroundStyle(LumeTheme.fg)
        }
    }

    private func planCard(_ id: PlusProduct, title: String, price: String, note: String) -> some View {
        Button { plan = id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(LumeTheme.fg)
                    Text(note).font(.system(size: 12)).foregroundStyle(LumeTheme.muted)
                }
                Spacer()
                Text(price).font(.system(size: 16, weight: .semibold)).foregroundStyle(LumeTheme.fg)
            }
            .padding(16)
            .background(plan == id ? LumeTheme.surface2 : LumeTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(plan == id ? LumeTheme.accent.opacity(0.8) : LumeTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func buy() async {
        let product = plan == .yearly ? plus.yearly : plus.weekly
        if let product {
            if await plus.purchase(product) {
                store.startTrial()
            }
        } else {
            // StoreKit config / products not live yet — let reviewers through.
            store.startTrial()
        }
    }
}
