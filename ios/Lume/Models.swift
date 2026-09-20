import Foundation

enum Screen: String, Codable {
    case onboarding, firstScan, analyzing, reveal, paywall, app
}

enum Tab: String, Codable { case today, scan, ritual, progress }
enum Period: String, Codable { case am, pm }

struct Profile: Codable, Equatable {
    var goal: String?
    var concerns: [String] = []
    var skinType: String?
    var routineLevel: String?
    var sleep: String?
    var ageRange: String?
}

struct Scores: Codable, Equatable {
    var glow: Int
    var evenness: Int
    var texture: Int
    var calm: Int
    var overall: Int

    static let zero = Scores(glow: 0, evenness: 0, texture: 0, calm: 0, overall: 0)
}

struct RitualStep: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var seconds: Int
    var period: Period
}

struct ScanRecord: Codable, Identifiable, Equatable {
    var id: String
    var at: Date
    var thumbName: String
    var scores: Scores
    var insights: [String]
    var focus: String
}

struct RitualLog: Codable, Equatable {
    var dateKey: String
    var amDone: [String]
    var pmDone: [String]

    static func fresh() -> RitualLog {
        RitualLog(dateKey: Date.lumeKey(), amDone: [], pmDone: [])
    }
}

struct Choice: Identifiable, Hashable {
    var id: String
    var label: String
    var blurb: String?
}

enum Catalog {
    static let goals: [Choice] = [
        .init(id: "awake", label: "Look more awake", blurb: "Brighter mornings, less dull"),
        .init(id: "calm", label: "Calm redness", blurb: "Less flush, more even"),
        .init(id: "clear", label: "Clear breakouts", blurb: "Fewer active spots"),
        .init(id: "smooth", label: "Smooth texture", blurb: "Finer, more even grain"),
        .init(id: "glow", label: "Hold onto glow", blurb: "That lit-from-inside look"),
    ]
    static let concerns: [Choice] = [
        .init(id: "dullness", label: "Dullness"),
        .init(id: "redness", label: "Redness"),
        .init(id: "breakouts", label: "Breakouts"),
        .init(id: "dry", label: "Dry patches"),
        .init(id: "oil", label: "Oil"),
        .init(id: "circles", label: "Dark circles"),
        .init(id: "texture", label: "Texture"),
        .init(id: "lines", label: "Fine lines"),
    ]
    static let skin: [Choice] = [
        .init(id: "dry", label: "Dry"),
        .init(id: "combo", label: "Combination"),
        .init(id: "oily", label: "Oily"),
        .init(id: "unsure", label: "Not sure"),
    ]
    static let routines: [Choice] = [
        .init(id: "splash", label: "Splash of water", blurb: "Bare minimum"),
        .init(id: "basic", label: "Cleanser and moisturizer", blurb: "The usual two"),
        .init(id: "full", label: "A full shelf", blurb: "Serums, acids, the lot"),
    ]
    static let sleep: [Choice] = [
        .init(id: "under6", label: "Under 6 hours"),
        .init(id: "6to7", label: "6–7 hours"),
        .init(id: "7to8", label: "7–8 hours"),
        .init(id: "over8", label: "8 hours or more"),
    ]
    static let ages: [Choice] = [
        .init(id: "u22", label: "Under 22"),
        .init(id: "22to29", label: "22–29"),
        .init(id: "30to39", label: "30–39"),
        .init(id: "40plus", label: "40+"),
    ]
}

extension Date {
    static func lumeKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

func scoreLabel(_ n: Int) -> String {
    if n >= 86 { return "Lit" }
    if n >= 76 { return "Steady" }
    if n >= 64 { return "Working" }
    return "Early"
}

enum MetricCopy {
    static let all: [(key: String, label: String, hint: String)] = [
        ("overall", "Glow index", "Weighted across light, evenness, grain, and calm."),
        ("glow", "Glow", "How much light the surface is giving back."),
        ("evenness", "Evenness", "Patchiness in tone across the face."),
        ("texture", "Texture", "Visible grain, roughness, and micro-contrast."),
        ("calm", "Calm", "Redness and heat sitting in the skin."),
    ]
}
