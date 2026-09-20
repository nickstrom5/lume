import UIKit

enum GlowAnalyzer {
    static func analyze(_ image: UIImage) -> Scores {
        guard let cg = downsample(image, width: 160) else { return fallback(from: image) }
        let w = cg.width
        let h = cg.height
        guard let data = pixelData(cg) else { return fallback(from: image) }

        let x0 = Int(Double(w) * 0.18)
        let x1 = Int(Double(w) * 0.82)
        let y0 = Int(Double(h) * 0.12)
        let y1 = Int(Double(h) * 0.88)

        var lum: [Double] = []
        var redAcc = 0.0
        var n = 0
        var texAcc = 0.0
        var texN = 0
        var hash = 0

        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * w + x) * 4
                let r = Double(data[i])
                let g = Double(data[i + 1])
                let b = Double(data[i + 2])
                hash = (hash &* 33 &+ Int(data[i])) & 0x7fffffff
                guard isSkin(r, g, b) else { continue }
                let L = 0.2126 * r + 0.7152 * g + 0.0722 * b
                lum.append(L)
                redAcc += (r - g) / max(r, 1)
                n += 1
                if x + 3 < x1 {
                    let j = (y * w + (x + 3)) * 4
                    let L2 = 0.2126 * Double(data[j]) + 0.7152 * Double(data[j + 1]) + 0.0722 * Double(data[j + 2])
                    texAcc += abs(L - L2)
                    texN += 1
                }
            }
        }

        let sample: [Double]
        if lum.count > 80 {
            sample = lum
        } else {
            var all: [Double] = []
            var i = 0
            while i + 2 < data.count {
                let r = Double(data[i])
                let g = Double(data[i + 1])
                let b = Double(data[i + 2])
                all.append(0.2126 * r + 0.7152 * g + 0.0722 * b)
                i += 16
            }
            sample = all
        }

        let mean = sample.reduce(0, +) / Double(max(sample.count, 1))
        let variance = sample.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(max(sample.count, 1))
        let std = sqrt(variance)
        let cv = mean == 0 ? 0 : std / mean
        let redness = n > 40 ? redAcc / Double(n) : 0.1
        let grain = texN > 40 ? texAcc / Double(texN) : 10
        let jitter = Double((hash % 5) - 2)

        let glow = clamp(map(mean, 72, 196, 46, 93) + jitter, 38, 96)
        let evenness = clamp(map(cv, 0.22, 0.045, 48, 94) + Double(Int(jitter) % 2), 40, 96)
        let texture = clamp(map(grain, 26, 5, 44, 92) - Double(Int(jitter) % 2), 38, 95)
        let calm = clamp(map(redness, 0.2, 0.03, 46, 93) + jitter, 40, 96)
        let overall = clamp(0.34 * glow + 0.26 * evenness + 0.22 * texture + 0.18 * calm, 40, 96)

        return Scores(
            glow: Int(glow.rounded()),
            evenness: Int(evenness.rounded()),
            texture: Int(texture.rounded()),
            calm: Int(calm.rounded()),
            overall: Int(overall.rounded())
        )
    }

    private static func isSkin(_ r: Double, _ g: Double, _ b: Double) -> Bool {
        let maxc = max(r, g, b)
        let minc = min(r, g, b)
        let sat = maxc == 0 ? 0 : (maxc - minc) / maxc
        return r > 70 && g > 40 && b > 25 && r > b && r >= g * 0.72 && sat < 0.62 && sat > 0.04
    }

    private static func downsample(_ image: UIImage, width: CGFloat) -> CGImage? {
        let size = image.size
        guard size.width > 0 else { return image.cgImage }
        let scale = min(1, width / size.width)
        let w = max(1, (size.width * scale).rounded())
        let h = max(1, (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        return rendered.cgImage
    }

    private static func pixelData(_ image: CGImage) -> [UInt8]? {
        let w = image.width
        let h = image.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &data,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return data
    }

    private static func fallback(from image: UIImage) -> Scores {
        let hash = Int(image.size.width + image.size.height * 13) % 7
        return Scores(
            glow: 62 + hash,
            evenness: 58 + hash,
            texture: 55 + hash,
            calm: 60 + hash,
            overall: 59 + hash
        )
    }

    private static func clamp(_ v: Double, _ a: Double, _ b: Double) -> Double {
        min(b, max(a, v))
    }

    private static func map(_ value: Double, _ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
        let t = clamp((value - a) / (b - a == 0 ? 1 : b - a), 0, 1)
        return c + t * (d - c)
    }
}

enum RitualPlan {
    static func build(_ profile: Profile) -> [RitualStep] {
        var am = Self.amBase
        var pm = Self.pmBase
        let c = Set(profile.concerns)

        if let i = am.firstIndex(where: { $0.id == "am-treat" }) {
            if c.contains("dullness") || profile.goal == "glow" || profile.goal == "awake" {
                am[i].title = "Vitamin C press"
                am[i].detail = "Antioxidant serum, five drops. This is your morning light."
            } else if c.contains("redness") || profile.goal == "calm" {
                am[i].title = "Centella or azelaic"
                am[i].detail = "A calming pass. No acids before you leave the house."
            } else if c.contains("breakouts") || profile.goal == "clear" {
                am[i].title = "Niacinamide"
                am[i].detail = "Lightweight, all over, not just the spots."
            }
        }

        if let i = pm.firstIndex(where: { $0.id == "pm-treat" }) {
            if profile.ageRange == "30to39" || profile.ageRange == "40plus" || c.contains("lines") {
                pm[i].title = "Retinoid, pea-size"
                pm[i].detail = "Every other night if you're new. Buffer with moisturizer if it bites."
            } else if c.contains("texture") || profile.goal == "smooth" {
                pm[i].title = "Leave-on exfoliant"
                pm[i].detail = "PHA or lactic, two nights a week. The others, skip to cream."
            } else if c.contains("breakouts") {
                pm[i].title = "Benzoyl or adapalene"
                pm[i].detail = "Thin layer on active zones. Not a mask."
            } else if c.contains("dry") {
                pm[i].title = "Hydrating serum"
                pm[i].detail = "Hyaluronic on damp skin, then cream immediately."
            }
        }

        if let i = pm.firstIndex(where: { $0.id == "pm-seal" }), profile.skinType == "dry" || c.contains("dry") {
            pm[i].title = "Cream, then oil"
            pm[i].detail = "Lock water in. Squalane or petrolatum on the dry map only."
        }

        if profile.sleep == "under6" || c.contains("circles"),
           let i = pm.firstIndex(where: { $0.id == "pm-eye" }) {
            pm[i].detail = "Cold metal or a chilled spoon for ten seconds, then the eye cream."
        }

        return am + pm
    }

    static func insights(_ scores: Scores, concerns: [String]) -> (insights: [String], focus: String) {
        let ranked: [(String, Int, String)] = [
            ("glow", scores.glow, "Light is sitting on the surface, not coming from it."),
            ("evenness", scores.evenness, "Tone is patchy in the T-zone and cheeks."),
            ("texture", scores.texture, "Grain is doing more work than it needs to."),
            ("calm", scores.calm, "Warmth in the skin is reading as tired, not flushed-pretty."),
        ].sorted { $0.1 < $1.1 }

        var lines: [String] = []
        if let weakest = ranked.first { lines.append(weakest.2) }

        if concerns.contains("circles") {
            lines.append("Under-eyes are taking the night shift for the rest of the face.")
        } else if concerns.contains("breakouts") {
            lines.append("Keep actives on a short leash — more is not faster.")
        } else if scores.glow >= 80 {
            lines.append("Glow is already a strength. Protect it with SPF like it's rent.")
        } else {
            lines.append("A sixty-second ritual beats a twelve-step shelf you skip.")
        }

        if scores.calm < 70 {
            lines.append("Skip fragrance this week. Barrier first, glow second.")
        } else if scores.texture < 70 {
            lines.append("Texture moves when you stop stacking acids on tired skin.")
        } else {
            lines.append("Consistency for fourteen days will show up in the trend line.")
        }

        let focusMap = [
            "glow": "Today: vitamin C press and nothing clever.",
            "evenness": "Today: one treatment, all over, then stop.",
            "texture": "Today: cleanse, hydrating serum, cream. No extra grit.",
            "calm": "Today: lukewarm water and a bland moisturizer.",
        ]
        let key = ranked.first?.0 ?? "glow"
        return (Array(lines.prefix(3)), focusMap[key] ?? "Today: the sixty-second version. All of it.")
    }

    static func period(_ steps: [RitualStep], _ period: Period) -> [RitualStep] {
        steps.filter { $0.period == period }
    }

    private static let amBase: [RitualStep] = [
        .init(id: "am-cleanse", title: "Rinse, don't strip", detail: "Cool water, or a gel cleanser if you woke up oily. Thirty seconds, no more.", seconds: 15, period: .am),
        .init(id: "am-treat", title: "Press a treatment", detail: "Niacinamide or vitamin C, five drops, press until it disappears.", seconds: 15, period: .am),
        .init(id: "am-seal", title: "Seal it", detail: "A pea of moisturizer. Damp skin, not dry.", seconds: 15, period: .am),
        .init(id: "am-spf", title: "SPF, even inside", detail: "Two fingers. Windows count. This is the whole game.", seconds: 15, period: .am),
    ]

    private static let pmBase: [RitualStep] = [
        .init(id: "pm-cleanse", title: "Take the day off", detail: "Double cleanse if you wore SPF or makeup. Gentle, not squeaky.", seconds: 15, period: .pm),
        .init(id: "pm-treat", title: "Tonight's active", detail: "One treatment. Not three. Skin heals in the dark.", seconds: 20, period: .pm),
        .init(id: "pm-eye", title: "Tap the orbital bone", detail: "Ring finger only. Caffeine or peptide. No dragging.", seconds: 10, period: .pm),
        .init(id: "pm-seal", title: "Occlude", detail: "Richer cream than morning. If you're dry, a last drop of oil on top.", seconds: 15, period: .pm),
    ]
}
