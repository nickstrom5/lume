import SwiftUI

/// Face on the primary pane, ritual/content on the secondary.
/// iOS 27.1 ArrangementView splits across the Duo inner display and
/// collapses to the secondary pane on a regular iPhone / outer display.
struct DuoLayout<Primary: View, Secondary: View>: View {
    @ViewBuilder var primary: () -> Primary
    @ViewBuilder var secondary: () -> Secondary
    @Environment(\.horizontalSizeClass) private var hClass

    var body: some View {
        if #available(iOS 27.1, *) {
            duoBody
        } else {
            fallback
        }
    }

    @available(iOS 27.1, *)
    private var duoBody: some View {
        ArrangementView {
            primary()
        } secondary: {
            secondary()
        }
        .arrangementViewStyle(.split.axes(.horizontal))
    }

    @ViewBuilder
    private var fallback: some View {
        if hClass == .regular {
            HStack(spacing: 0) {
                primary()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Rectangle()
                    .fill(LumeTheme.border.opacity(0.6))
                    .frame(width: 1)
                secondary()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            secondary()
        }
    }
}

struct FacePane: View {
    var image: UIImage?
    var caption: String
    var placeholder = "still"

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let named = UIImage(named: placeholder) {
                    Image(uiImage: named)
                        .resizable()
                        .scaledToFill()
                } else {
                    LumeTheme.surface
                }
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, LumeTheme.bg.opacity(0.85)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            Text(caption)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LumeTheme.fg)
                .padding(24)
        }
        .clipped()
        .ignoresSafeArea()
    }
}

struct Wordmark: View {
    var taps: (() -> Void)? = nil
    @State private var count = 0

    var body: some View {
        Button {
            count += 1
            if count >= 7 {
                count = 0
                taps?()
            }
        } label: {
            HStack(spacing: 8) {
                DawnMark()
                    .frame(width: 22, height: 22)
                Text("Lume")
                    .font(.display(20))
                    .foregroundStyle(LumeTheme.fg)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lume")
    }
}

struct DawnMark: View {
    var body: some View {
        Canvas { ctx, size in
            let r = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height * 0.56)
            for i in [1.0, 0.62, 0.28] {
                let rect = CGRect(
                    x: center.x - r * i,
                    y: center.y - r * i,
                    width: r * 2 * i,
                    height: r * 2 * i
                )
                ctx.fill(Path(ellipseIn: rect), with: .color(LumeTheme.fg.opacity(i == 0.28 ? 1 : 0.22 * i)))
            }
        }
    }
}

struct LumeButton: View {
    var title: String
    var fill = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(fill ? LumeTheme.accent : LumeTheme.surface)
                .foregroundStyle(fill ? LumeTheme.bg : LumeTheme.fg)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if !fill {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(LumeTheme.border, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct ScoreRing: View {
    var value: Int
    var size: CGFloat = 132
    var label = "Glow"

    var body: some View {
        ZStack {
            Circle().stroke(LumeTheme.border, lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(value, 0), 100)) / 100)
                .stroke(LumeTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.display(size * 0.28))
                    .foregroundStyle(LumeTheme.fg)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(LumeTheme.muted)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
        }
        .frame(width: size, height: size)
    }
}

struct Kicker: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(LumeTheme.muted)
            .textCase(.uppercase)
            .tracking(2.4)
    }
}
