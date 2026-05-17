//
//  PrefControls.swift
//  Kubarik
//
//  Shared building blocks for Profile/Settings: card section, label row,
//  custom toggle switch, stat card. All match the cream-warm visual
//  language used by the rest of the game.
//

import SwiftUI

struct PrefSection<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(Palette.taglineBrown)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Palette.textBrown.opacity(0.10), lineWidth: 1)
                    )
            )
        }
    }
}

struct PrefRow<Control: View>: View {
    let label: String
    var divider: Bool = false
    @ViewBuilder var control: () -> Control

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textBrown)
                Spacer()
                control()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if divider {
                Rectangle()
                    .fill(Palette.textBrown.opacity(0.10))
                    .frame(height: 1)
                    .padding(.leading, 16)
            }
        }
    }
}

/// Tappable row that opens an external destination. Use for "report a bug",
/// "view on GitHub", or anything else that kicks out of the app. The chevron
/// hints at the external nature without spelling it out.
struct PrefLinkRow: View {
    let label: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Palette.textBrown.opacity(0.85))
                        .frame(width: 22)
                }

                Text(label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textBrown)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundStyle(Palette.taglineBrown.opacity(0.75))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ToggleSwitch: View {
    @Binding var isOn: Bool

    private let trackOn = TileColor.turquoise
    private let trackOff = Color(hex: 0x8C643C).opacity(0.28)

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.20, dampingFraction: 0.65)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isOn ? AnyShapeStyle(trackOn.top) : AnyShapeStyle(trackOff))
                    .frame(width: 50, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: isOn ? trackOn.edge : .clear, radius: 0, x: 0, y: 2)

                Circle()
                    .fill(.white)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 3)
                    .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Three-way pill picker. Matches the segmented control in the design
/// (warm brown background, sliding cream thumb).
struct HapticLevelPicker: View {
    @Binding var value: HapticLevel

    private let options: [HapticLevel] = [.off, .medium, .high]

    var body: some View {
        let activeIdx = options.firstIndex(of: value) ?? 1

        GeometryReader { proxy in
            let inset: CGFloat = 3
            let thumbWidth = (proxy.size.width - inset * 2) / CGFloat(options.count)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: 0x8C643C).opacity(0.14))

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: 0xFFF8EE))
                    .shadow(color: Color(hex: 0x785028).opacity(0.18), radius: 2, x: 0, y: 1)
                    .frame(width: thumbWidth, height: proxy.size.height - inset * 2)
                    .offset(x: inset + CGFloat(activeIdx) * thumbWidth, y: inset)
                    .animation(.spring(response: 0.24, dampingFraction: 0.75), value: value)

                HStack(spacing: 0) {
                    ForEach(options, id: \.rawValue) { level in
                        Button(action: {
                            value = level
                        }) {
                            Text(level.label)
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(value == level
                                    ? Palette.textBrown
                                    : Palette.taglineBrown.opacity(0.85))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(width: 200, height: 32)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: TileColor
    let iconName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TileView(color: color, size: 32, radius: 9, depth: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 2)

            Text(value)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.textBrown)
                .monospacedDigit()
                .lineLimit(1)

            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Palette.taglineBrown)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Palette.textBrown.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
