import SwiftUI

struct OnboardingView: View {
    @Environment(LumeStore.self) private var store
    private let total = 8

    var body: some View {
        @Bindable var store = store
        DuoLayout {
            FacePane(image: UIImage(named: "still"), caption: story.kicker)
        } secondary: {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Wordmark { store.seedForReview() }
                    Spacer()
                    Text("\(store.onboardingStep + 1) / \(total)")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(LumeTheme.muted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        stepBody
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }

                HStack(spacing: 12) {
                    if store.onboardingStep > 0 {
                        Button("Back") {
                            store.onboardingStep -= 1
                        }
                        .foregroundStyle(LumeTheme.muted)
                    }
                    LumeButton(title: store.onboardingStep == total - 1 ? "See my ritual" : "Continue") {
                        if store.onboardingStep >= total - 1 {
                            store.finishOnboarding()
                        } else {
                            store.onboardingStep += 1
                        }
                    }
                    .disabled(!canNext)
                    .opacity(canNext ? 1 : 0.45)
                }
                .padding(20)
            }
            .background(LumeTheme.bg)
        }
    }

    private var canNext: Bool {
        switch store.onboardingStep {
        case 0: true
        case 1: store.profile.goal != nil
        case 2: !store.profile.concerns.isEmpty
        case 3: store.profile.skinType != nil
        case 4: store.profile.routineLevel != nil
        case 5: store.profile.sleep != nil
        case 6: store.profile.ageRange != nil
        default: true
        }
    }

    @ViewBuilder
    private var stepBody: some View {
        switch store.onboardingStep {
        case 0:
            Kicker(text: "Daily glow coach")
            Text("One photo. Sixty seconds.")
                .font(.display(34))
                .foregroundStyle(LumeTheme.fg)
            Text("A glow score from a photo you take in the same window every morning, then a ritual you will actually finish. Photos stay on this device.")
                .font(.system(size: 15))
                .foregroundStyle(LumeTheme.muted)
                .lineSpacing(4)
            Button("See a sample reading") { store.skipToSample() }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LumeTheme.accent)
                .padding(.top, 8)
        case 1:
            prompt("What do you want", Catalog.goals, selected: store.profile.goal) { id in
                store.patchProfile { $0.goal = $0.goal == id ? nil : id }
            }
        case 2:
            Kicker(text: "Pick what shows up")
            Text("What bothers you.")
                .font(.display(32))
                .foregroundStyle(LumeTheme.fg)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Catalog.concerns) { item in
                    ChoiceChip(title: item.label, on: store.profile.concerns.contains(item.id)) {
                        store.toggleConcern(item.id)
                    }
                }
            }
        case 3:
            prompt("Skin type", Catalog.skin, selected: store.profile.skinType) { id in
                store.patchProfile { $0.skinType = id }
            }
        case 4:
            prompt("Right now your routine is", Catalog.routines, selected: store.profile.routineLevel) { id in
                store.patchProfile { $0.routineLevel = id }
            }
        case 5:
            prompt("Sleep", Catalog.sleep, selected: store.profile.sleep) { id in
                store.patchProfile { $0.sleep = id }
            }
        case 6:
            prompt("Age", Catalog.ages, selected: store.profile.ageRange) { id in
                store.patchProfile { $0.ageRange = id }
            }
        default:
            Kicker(text: "Not a medical device")
            Text("A map, not a diagnosis.")
                .font(.display(32))
                .foregroundStyle(LumeTheme.fg)
            Text("Lume does not diagnose or treat. If something on your skin worries you, see someone who can look in person. Photos never leave this phone.")
                .font(.system(size: 15))
                .foregroundStyle(LumeTheme.muted)
                .lineSpacing(4)
        }
    }

    private func prompt(_ title: String, _ items: [Choice], selected: String?, pick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Kicker(text: "Tell Lume")
            Text(title)
                .font(.display(32))
                .foregroundStyle(LumeTheme.fg)
            ForEach(items) { item in
                Button {
                    pick(item.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.label)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(LumeTheme.fg)
                        if let blurb = item.blurb {
                            Text(blurb)
                                .font(.system(size: 13))
                                .foregroundStyle(LumeTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(selected == item.id ? LumeTheme.surface2 : LumeTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected == item.id ? LumeTheme.accent.opacity(0.7) : LumeTheme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var story: (kicker: String, title: String) {
        switch store.onboardingStep {
        case 0: ("iPhone · iPhone Duo", "The sixty seconds actually happen.")
        case 1: ("Goal", store.profile.goal.flatMap { id in Catalog.goals.first { $0.id == id }?.label } ?? "Pick a direction.")
        default: ("Lume", "Face left. Ritual right.")
        }
    }
}

struct ChoiceChip: View {
    var title: String
    var on: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(on ? LumeTheme.surface2 : LumeTheme.surface)
                .foregroundStyle(LumeTheme.fg)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(on ? LumeTheme.accent.opacity(0.7) : LumeTheme.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
