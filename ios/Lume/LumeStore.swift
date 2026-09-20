import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class LumeStore {
    var screen: Screen = .onboarding
    var tab: Tab = .today
    var onboardingStep = 0
    var profile = Profile()
    var ritual: [RitualStep] = []
    var scans: [ScanRecord] = []
    var ritualLog = RitualLog.fresh()
    var streak = 0
    var lastCompleteDate: String?
    var trialStartedAt: Date?
    var pendingScan: ScanRecord?
    var thumbs: [String: UIImage] = [:]

    private let defaultsKey = "lume-v1"

    init() {
        load()
        if screen == .analyzing { screen = pendingScan == nil ? .firstScan : .reveal }
        ensureLog()
    }

    var currentPeriod: Period {
        Calendar.current.component(.hour, from: Date()) < 14 ? .am : .pm
    }

    var latest: ScanRecord? { scans.first }

    func patchProfile(_ patch: (inout Profile) -> Void) {
        patch(&profile)
        save()
    }

    func toggleConcern(_ id: String) {
        if let i = profile.concerns.firstIndex(of: id) {
            profile.concerns.remove(at: i)
        } else {
            profile.concerns.append(id)
        }
        save()
    }

    func finishOnboarding() {
        ritual = RitualPlan.build(profile)
        screen = .firstScan
        save()
    }

    func skipToSample() {
        profile = Profile(
            goal: "awake",
            concerns: ["dullness", "texture"],
            skinType: "combo",
            routineLevel: "basic",
            sleep: "7to8",
            ageRange: "22to29"
        )
        ritual = RitualPlan.build(profile)
        onboardingStep = 7
        screen = .firstScan
        save()
    }

    func ingest(image: UIImage, name: String? = nil) {
        let thumbName = name ?? "scan-\(UUID().uuidString)"
        thumbs[thumbName] = image
        persistThumb(image, name: thumbName)
        let scores = GlowAnalyzer.analyze(image)
        let copy = RitualPlan.insights(scores, concerns: profile.concerns)
        pendingScan = ScanRecord(
            id: UUID().uuidString,
            at: Date(),
            thumbName: thumbName,
            scores: scores,
            insights: copy.insights,
            focus: copy.focus
        )
        screen = .analyzing
        save()
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            if screen == .analyzing { goReveal() }
        }
    }

    func goReveal() { screen = .reveal; save() }
    func goPaywall() { screen = .paywall; save() }

    func startTrial() {
        if let pendingScan {
            scans = ([pendingScan] + scans.filter { $0.id != pendingScan.id }).prefix(14).map { $0 }
        }
        trialStartedAt = Date()
        self.pendingScan = nil
        screen = .app
        tab = .today
        save()
    }

    func addScan(_ scan: ScanRecord) {
        scans = ([scan] + scans.filter { $0.id != scan.id }).prefix(14).map { $0 }
        tab = .scan
        save()
    }

    func commitPendingIfNeeded() {
        guard let pendingScan else { return }
        addScan(pendingScan)
        self.pendingScan = nil
        save()
    }

    func toggleRitual(_ id: String) {
        guard let step = ritual.first(where: { $0.id == id }) else { return }
        ensureLog()
        if step.period == .am {
            if let i = ritualLog.amDone.firstIndex(of: id) { ritualLog.amDone.remove(at: i) }
            else { ritualLog.amDone.append(id) }
        } else {
            if let i = ritualLog.pmDone.firstIndex(of: id) { ritualLog.pmDone.remove(at: i) }
            else { ritualLog.pmDone.append(id) }
        }
        let amIds = ritual.filter { $0.period == .am }.map(\.id)
        let pmIds = ritual.filter { $0.period == .pm }.map(\.id)
        let amDone = amIds.allSatisfy { ritualLog.amDone.contains($0) }
        let pmDone = pmIds.allSatisfy { ritualLog.pmDone.contains($0) }
        let today = Date.lumeKey()
        if (amDone || pmDone), lastCompleteDate != today {
            let yesterday = Date.lumeKey(Date().addingTimeInterval(-86400))
            streak = lastCompleteDate == yesterday ? streak + 1 : 1
            lastCompleteDate = today
        }
        save()
    }

    func seedForReview() {
        profile = Profile(
            goal: "awake",
            concerns: ["dullness", "texture", "circles"],
            skinType: "combo",
            routineLevel: "basic",
            sleep: "7to8",
            ageRange: "22to29"
        )
        ritual = RitualPlan.build(profile)
        let a = UIImage(named: "scan-a") ?? UIImage(named: "still")
        let b = UIImage(named: "scan-b") ?? a
        if let a { thumbs["scan-a"] = a }
        if let b { thumbs["scan-b"] = b }
        scans = reviewDays.enumerated().map { i, day in
            ScanRecord(
                id: "review-\(i)",
                at: Date().addingTimeInterval(-Double(day.ago) * 86400),
                thumbName: i % 2 == 0 ? "scan-a" : "scan-b",
                scores: Scores(glow: day.glow, evenness: day.evenness, texture: day.texture, calm: day.calm, overall: day.overall),
                insights: day.insights,
                focus: day.focus
            )
        }
        let amIds = ritual.filter { $0.period == .am }.map(\.id)
        ritualLog = RitualLog(dateKey: Date.lumeKey(), amDone: amIds, pmDone: [])
        streak = 7
        lastCompleteDate = Date.lumeKey()
        trialStartedAt = Date().addingTimeInterval(-3 * 86400)
        pendingScan = nil
        screen = .app
        tab = .today
        onboardingStep = 7
        save()
    }

    func resetDemo() {
        screen = .onboarding
        tab = .today
        onboardingStep = 0
        profile = Profile()
        ritual = []
        scans = []
        ritualLog = .fresh()
        streak = 0
        lastCompleteDate = nil
        trialStartedAt = nil
        pendingScan = nil
        thumbs = [:]
        save()
    }

    func deleteMyData() { resetDemo() }

    func thumb(for name: String) -> UIImage? {
        if let cached = thumbs[name] { return cached }
        if let disk = loadThumb(name) {
            thumbs[name] = disk
            return disk
        }
        return UIImage(named: name)
    }

    func imageForLatest() -> UIImage? {
        if let name = latest?.thumbName { return thumb(for: name) }
        return UIImage(named: "still")
    }

    private func ensureLog() {
        let today = Date.lumeKey()
        if ritualLog.dateKey != today {
            ritualLog = RitualLog(dateKey: today, amDone: [], pmDone: [])
        }
    }

    private struct Disk: Codable {
        var screen: Screen
        var tab: Tab
        var onboardingStep: Int
        var profile: Profile
        var ritual: [RitualStep]
        var scans: [ScanRecord]
        var ritualLog: RitualLog
        var streak: Int
        var lastCompleteDate: String?
        var trialStartedAt: Date?
        var pendingScan: ScanRecord?
    }

    private func save() {
        let disk = Disk(
            screen: screen == .analyzing ? .reveal : screen,
            tab: tab,
            onboardingStep: onboardingStep,
            profile: profile,
            ritual: ritual,
            scans: scans,
            ritualLog: ritualLog,
            streak: streak,
            lastCompleteDate: lastCompleteDate,
            trialStartedAt: trialStartedAt,
            pendingScan: pendingScan
        )
        if let data = try? JSONEncoder().encode(disk) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let disk = try? JSONDecoder().decode(Disk.self, from: data) else { return }
        screen = disk.screen
        tab = disk.tab
        onboardingStep = disk.onboardingStep
        profile = disk.profile
        ritual = disk.ritual
        scans = disk.scans
        ritualLog = disk.ritualLog
        streak = disk.streak
        lastCompleteDate = disk.lastCompleteDate
        trialStartedAt = disk.trialStartedAt
        pendingScan = disk.pendingScan
    }

    private func persistThumb(_ image: UIImage, name: String) {
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        let url = thumbsDir.appendingPathComponent("\(name).jpg")
        try? FileManager.default.createDirectory(at: thumbsDir, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private func loadThumb(_ name: String) -> UIImage? {
        let url = thumbsDir.appendingPathComponent("\(name).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private var thumbsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thumbs", isDirectory: true)
    }
}

private struct ReviewDay {
    var ago: Int
    var overall: Int
    var glow: Int
    var evenness: Int
    var texture: Int
    var calm: Int
    var focus: String
    var insights: [String]
}

private let reviewDays: [ReviewDay] = [
    .init(ago: 0, overall: 68, glow: 70, evenness: 67, texture: 64, calm: 69, focus: "Same window. Same hour.", insights: ["Glow is climbing because the mornings actually happened.", "Texture is quieter than day one.", "Do not add a step. Sixty seconds is the product."]),
    .init(ago: 1, overall: 64, glow: 66, evenness: 64, texture: 60, calm: 66, focus: "SPF even on an indoor day.", insights: ["Light is coming back.", "Evenness moved first.", "Keep the ritual short."]),
    .init(ago: 2, overall: 61, glow: 62, evenness: 61, texture: 57, calm: 63, focus: "Press treatment on damp skin.", insights: ["The line is a line now.", "Under-eyes quieter.", "No third active."]),
    .init(ago: 3, overall: 58, glow: 58, evenness: 59, texture: 54, calm: 60, focus: "Tap the orbital bone. No dragging.", insights: ["Calm is holding.", "Glow follows SPF more than serum.", "Texture still grain, not breakout."]),
    .init(ago: 4, overall: 56, glow: 55, evenness: 57, texture: 52, calm: 58, focus: "Press treatment on damp skin, not dry.", insights: ["Evenness wants to move.", "Texture still reads as grain.", "The ritual is landing."]),
    .init(ago: 5, overall: 54, glow: 52, evenness: 55, texture: 51, calm: 56, focus: "Keep SPF even on an indoor day.", insights: ["Glow ticked up after two honest mornings.", "Under-eyes quieter when you rinse.", "Do not add a third active."]),
    .init(ago: 6, overall: 51, glow: 48, evenness: 54, texture: 49, calm: 55, focus: "Same window. Same hour. Let the line start.", insights: ["Morning light is flatter than the serum suggests.", "Texture is loudest on the cheeks.", "The dullness is the whole story."]),
]
