import SwiftUI

struct AppTabs: View {
    @Environment(LumeStore.self) private var store
    @State private var camera = false

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)
            ScanTab(camera: $camera)
                .tabItem { Label("Scan", systemImage: "camera") }
                .tag(Tab.scan)
            RitualView()
                .tabItem { Label("Ritual", systemImage: "drop") }
                .tag(Tab.ritual)
            ProgressViewTab()
                .tabItem { Label("Trend", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)
        }
        .toolbarBackground(LumeTheme.bg, for: .tabBar)
        .fullScreenCover(isPresented: $camera) {
            CameraPicker { image in
                camera = false
                if let image {
                    store.ingest(image: image)
                    store.commitPendingIfNeeded()
                    store.screen = .app
                    store.tab = .scan
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct TodayView: View {
    @Environment(LumeStore.self) private var store
    @State private var settings = false

    var body: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
        let scannedToday = store.latest.map { Date.lumeKey($0.at) == Date.lumeKey() } ?? false
        let steps = RitualPlan.period(store.ritual, store.currentPeriod)
        let done = store.currentPeriod == .am ? store.ritualLog.amDone : store.ritualLog.pmDone
        let doneCount = steps.filter { done.contains($0.id) }.count

        DuoLayout {
            FacePane(
                image: store.imageForLatest(),
                caption: store.latest.map { "\($0.scores.overall) · \(scoreLabel($0.scores.overall))" } ?? "Scan to open the map"
            )
        } secondary: {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Wordmark { store.seedForReview() }
                        Spacer()
                        Button { settings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(LumeTheme.muted)
                                .frame(width: 44, height: 44)
                        }
                    }
                    Kicker(text: greeting)
                    Text(scannedToday ? "Today is already on the map." : "You haven’t scanned today.")
                        .font(.display(32))
                        .foregroundStyle(LumeTheme.fg)
                    Text(store.latest?.focus ?? "A sixty-second ritual. Then a photo so you can watch the line move.")
                        .font(.system(size: 15))
                        .foregroundStyle(LumeTheme.muted)

                    HStack(spacing: 20) {
                        ScoreRing(value: store.latest?.scores.overall ?? 0)
                        VStack(alignment: .leading, spacing: 14) {
                            stat("\(store.streak)", "day streak")
                            stat("\(doneCount)/\(max(steps.count, 4))", store.currentPeriod == .am ? "morning" : "evening")
                            stat("\(store.scans.count)", "scans")
                        }
                    }
                    .padding(.top, 8)

                    LumeButton(title: scannedToday ? "Open ritual" : "Scan now") {
                        store.tab = scannedToday ? .ritual : .scan
                    }
                    LumeButton(title: scannedToday ? "Rescan" : "Open ritual", fill: false) {
                        store.tab = scannedToday ? .scan : .ritual
                    }
                }
                .padding(20)
            }
            .background(LumeTheme.bg)
            .sheet(isPresented: $settings) { SettingsSheet() }
        }
    }

    private func stat(_ n: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(n).font(.system(size: 20, weight: .semibold, design: .rounded)).foregroundStyle(LumeTheme.fg)
            Text(l).font(.system(size: 12)).foregroundStyle(LumeTheme.muted)
        }
    }
}

struct ScanTab: View {
    @Environment(LumeStore.self) private var store
    @Binding var camera: Bool

    var body: some View {
        DuoLayout {
            FacePane(
                image: store.imageForLatest(),
                caption: store.latest.map { Date.lumeKey($0.at) } ?? "No scan yet"
            )
        } secondary: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Wordmark { store.seedForReview() }
                    Kicker(text: "Scan")
                    Text("Same window. Same hour.")
                        .font(.display(32))
                        .foregroundStyle(LumeTheme.fg)
                    if let scan = store.latest {
                        ScoreRing(value: scan.scores.overall)
                        metric("Glow", scan.scores.glow)
                        metric("Evenness", scan.scores.evenness)
                        metric("Texture", scan.scores.texture)
                        metric("Calm", scan.scores.calm)
                        ForEach(scan.insights, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 14))
                                .foregroundStyle(LumeTheme.muted)
                        }
                    } else {
                        Text("The first photo is the baseline. Indoor daylight. No filter.")
                            .font(.system(size: 15))
                            .foregroundStyle(LumeTheme.muted)
                    }
                    LumeButton(title: "Take today’s photo") { camera = true }
                    LumeButton(title: "Use sample photo", fill: false) {
                        if let img = UIImage(named: "scan-b") ?? UIImage(named: "still") {
                            store.ingest(image: img, name: "scan-b")
                            store.commitPendingIfNeeded()
                            store.screen = .app
                            store.tab = .scan
                        }
                    }
                }
                .padding(20)
            }
            .background(LumeTheme.bg)
        }
    }

    private func metric(_ l: String, _ n: Int) -> some View {
        HStack {
            Text(l).foregroundStyle(LumeTheme.muted)
            Spacer()
            Text("\(n)").fontWeight(.semibold)
        }
        .font(.system(size: 15))
        .foregroundStyle(LumeTheme.fg)
    }
}

struct RitualView: View {
    @Environment(LumeStore.self) private var store
    @State private var playing: RitualStep?
    @State private var remaining = 0
    @State private var ticker: Timer?

    var body: some View {
        let period = store.currentPeriod
        let steps = RitualPlan.period(store.ritual, period)
        let done = period == .am ? store.ritualLog.amDone : store.ritualLog.pmDone

        DuoLayout {
            FacePane(image: store.imageForLatest(), caption: period == .am ? "Morning · 60s" : "Evening · 60s")
        } secondary: {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Wordmark { store.seedForReview() }
                    Kicker(text: period == .am ? "Morning" : "Evening")
                    Text("Sixty seconds. Then done.")
                        .font(.display(28))
                        .foregroundStyle(LumeTheme.fg)
                }
                .padding(20)

                if let playing {
                    VStack(spacing: 12) {
                        Text(playing.title).font(.display(24)).foregroundStyle(LumeTheme.fg)
                        Text(playing.detail).font(.system(size: 15)).foregroundStyle(LumeTheme.muted).multilineTextAlignment(.center)
                        Text("\(remaining)s")
                            .font(.system(size: 48, weight: .medium, design: .rounded))
                            .foregroundStyle(LumeTheme.fg)
                        LumeButton(title: "Done") { finishStep(playing) }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(steps) { step in
                                Button {
                                    store.toggleRitual(step.id)
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: done.contains(step.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(done.contains(step.id) ? LumeTheme.success : LumeTheme.muted)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(step.title).font(.system(size: 16, weight: .medium)).foregroundStyle(LumeTheme.fg)
                                            Text(step.detail).font(.system(size: 13)).foregroundStyle(LumeTheme.muted)
                                        }
                                        Spacer()
                                        Text("\(step.seconds)s").font(.system(size: 12)).foregroundStyle(LumeTheme.subtle)
                                    }
                                    .padding(14)
                                    .background(LumeTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    LumeButton(title: "Play ritual") {
                        if let first = steps.first(where: { !done.contains($0.id) }) ?? steps.first {
                            start(first)
                        }
                    }
                    .padding(20)
                }
            }
            .background(LumeTheme.bg)
            .onDisappear { ticker?.invalidate() }
        }
    }

    private func start(_ step: RitualStep) {
        playing = step
        remaining = step.seconds
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                remaining -= 1
                if remaining <= 0, let playing { finishStep(playing) }
            }
        }
    }

    private func finishStep(_ step: RitualStep) {
        ticker?.invalidate()
        if !(store.currentPeriod == .am ? store.ritualLog.amDone : store.ritualLog.pmDone).contains(step.id) {
            store.toggleRitual(step.id)
        }
        let steps = RitualPlan.period(store.ritual, store.currentPeriod)
        let done = store.currentPeriod == .am ? store.ritualLog.amDone : store.ritualLog.pmDone
        if let next = steps.first(where: { !done.contains($0.id) }) {
            start(next)
        } else {
            playing = nil
        }
    }
}

struct ProgressViewTab: View {
    @Environment(LumeStore.self) private var store

    var body: some View {
        let points = store.scans.reversed()
        DuoLayout {
            FacePane(image: store.imageForLatest(), caption: "Fourteen days")
        } secondary: {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Wordmark { store.seedForReview() }
                    Kicker(text: "Trend")
                    Text("Watch the line move.")
                        .font(.display(32))
                        .foregroundStyle(LumeTheme.fg)
                    if points.isEmpty {
                        Text("Two scans make a line. One scan is a point.")
                            .foregroundStyle(LumeTheme.muted)
                    } else {
                        GeometryReader { geo in
                            let vals = points.map { CGFloat($0.scores.overall) }
                            let minV = (vals.min() ?? 40) - 4
                            let maxV = (vals.max() ?? 90) + 4
                            Path { p in
                                for (i, v) in vals.enumerated() {
                                    let x = geo.size.width * CGFloat(i) / CGFloat(max(vals.count - 1, 1))
                                    let y = geo.size.height * (1 - (v - minV) / max(maxV - minV, 1))
                                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                                }
                            }
                            .stroke(LumeTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        }
                        .frame(height: 160)
                        .padding(.vertical, 8)

                        ForEach(store.scans) { scan in
                            HStack {
                                Text(Date.lumeKey(scan.at)).foregroundStyle(LumeTheme.muted)
                                Spacer()
                                Text("\(scan.scores.overall)").fontWeight(.semibold)
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(LumeTheme.fg)
                        }
                    }
                }
                .padding(20)
            }
            .background(LumeTheme.bg)
        }
    }
}

struct SettingsSheet: View {
    @Environment(LumeStore.self) private var store
    @Environment(PlusStore.self) private var plus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Lume") {
                    Link("Privacy", destination: URL(string: "https://lumenow.app/privacy.html")!)
                    Link("Terms", destination: URL(string: "https://lumenow.app/terms.html")!)
                    Link("Support", destination: URL(string: "https://lumenow.app/support.html")!)
                    Button("Restore purchases") {
                        Task { await plus.restore() }
                    }
                }
                Section("This device") {
                    Button("Seed review state", role: nil) { store.seedForReview(); dismiss() }
                    Button("Reset demo") { store.resetDemo(); dismiss() }
                    Button("Delete my data", role: .destructive) { store.deleteMyData(); dismiss() }
                }
                Section {
                    Text("Not a medical device. Coaching only. Photos stay on this iPhone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(LumeTheme.bg)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
