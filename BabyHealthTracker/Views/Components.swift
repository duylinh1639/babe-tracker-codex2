import SwiftUI

struct SectionTitle: View {
    var title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.rounded(11, weight: .bold))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.rounded(12, weight: .semibold))
            }
        }
        .padding(.horizontal, 2)
    }
}

struct MetricCard: View {
    var icon: String
    var value: String
    var label: String
    var tint: Color
    var background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.rounded(20, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.rounded(11, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QuickLogButton: View {
    var title: String
    var icon: String
    var tint: Color
    var background: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.rounded(12, weight: .bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

struct Badge: View {
    var title: String
    var tint: Color
    var background: Color?

    var body: some View {
        Text(title)
            .font(.rounded(11, weight: .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background ?? tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct EmptyState: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            Text(title)
                .font(.rounded(15, weight: .bold))

            Text(subtitle)
                .font(.rounded(13))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appCard(radius: 16)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct MiniBarChart: View {
    var values: [Double]
    var labels: [String]
    var tint: Color
    var targetRange: ClosedRange<Double>?

    private var maxValue: Double {
        max(values.max() ?? 1, targetRange?.upperBound ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                HStack(spacing: 10) {
                    Text(labels.indices.contains(index) ? labels[index] : "")
                        .font(.rounded(11, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 32, alignment: .leading)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(tint.opacity(0.12))

                            Capsule()
                                .fill(value < (targetRange?.lowerBound ?? 0) ? Color.appAlert.opacity(0.72) : tint)
                                .frame(width: max(proxy.size.width * value / maxValue, 4))

                            if let targetRange {
                                let lower = proxy.size.width * targetRange.lowerBound / maxValue
                                let upper = proxy.size.width * targetRange.upperBound / maxValue
                                Capsule()
                                    .fill(Color.appAlert.opacity(0.18))
                                    .frame(width: max(upper - lower, 2))
                                    .offset(x: lower)
                            }
                        }
                    }
                    .frame(height: 12)

                    Text(String(format: "%.1f", value))
                        .font(.rounded(11, weight: .bold))
                        .frame(width: 34, alignment: .trailing)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
