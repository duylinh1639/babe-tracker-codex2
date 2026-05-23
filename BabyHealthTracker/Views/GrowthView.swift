import SwiftUI

struct GrowthView: View {
    @EnvironmentObject private var store: BabyHealthStore
    @State private var metric: GrowthMetric = .weight
    @State private var activeSheet: LogSheet?

    var body: some View {
        if let profile = store.activeProfile {
            NavigationStack {
                ZStack {
                    Color.growthBackground.ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            MetricSelector(metric: $metric)
                            GrowthChartCard(profile: profile, metric: metric)
                            GrowthHistory(profile: profile)
                        }
                        .padding(16)
                    }
                }
                .navigationTitle("Growth")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            activeSheet = .growth
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(item: $activeSheet) { sheet in
                    LogSheetHost(sheet: sheet, profile: profile)
                        .presentationDetents([.medium, .large])
                }
            }
        } else {
            OnboardingView()
        }
    }
}

private struct MetricSelector: View {
    @Binding var metric: GrowthMetric

    var body: some View {
        Picker("Metric", selection: $metric) {
            ForEach(GrowthMetric.allCases) { metric in
                Text(metric.title).tag(metric)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct GrowthChartCard: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile
    var metric: GrowthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WHO chart")
                        .font(.rounded(18, weight: .bold))
                    Text(percentileText)
                        .font(.rounded(13, weight: .semibold))
                        .foregroundStyle(Color.growth)
                }

                Spacer()

                Badge(title: metric.unit, tint: .growth)
            }

            GrowthLineChart(entries: entries, metric: metric)
                .frame(height: 220)

            Text("Percentiles are lightweight demo estimates. Replace with official WHO LMS data before production medical use.")
                .font(.rounded(12))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(16)
        .appCard()
    }

    private var entries: [GrowthEntry] {
        store.growthEntries(for: profile)
    }

    private var percentileText: String {
        guard let latest = entries.last else { return "No measurements yet" }
        let value = value(for: latest)
        let percentile = min(max(Int((value / referenceMedian) * 50), 3), 97)
        return "\(percentile)th percentile - \(String(format: "%.1f", value)) \(metric.unit)"
    }

    private var referenceMedian: Double {
        switch metric {
        case .weight: return 10.0
        case .height: return 81.0
        case .head: return 46.0
        }
    }

    private func value(for entry: GrowthEntry) -> Double {
        switch metric {
        case .weight: return entry.weightKg
        case .height: return entry.heightCm
        case .head: return entry.headCircumferenceCm
        }
    }
}

private struct GrowthLineChart: View {
    var entries: [GrowthEntry]
    var metric: GrowthMetric

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.growth.opacity(0.08))

                grid(in: proxy.size)
                    .stroke(Color.growth.opacity(0.16), lineWidth: 1)

                referenceBand(in: proxy.size)
                    .fill(Color.growth.opacity(0.10))

                linePath(in: proxy.size)
                    .stroke(Color.growth, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                points(in: proxy.size)
            }
        }
        .accessibilityLabel("Growth chart")
    }

    private var values: [Double] {
        entries.map { entry in
            switch metric {
            case .weight: return entry.weightKg
            case .height: return entry.heightCm
            case .head: return entry.headCircumferenceCm
            }
        }
    }

    private var range: ClosedRange<Double> {
        guard let minValue = values.min(), let maxValue = values.max(), minValue != maxValue else {
            return 0...1
        }

        let padding = (maxValue - minValue) * 0.25
        return (minValue - padding)...(maxValue + padding)
    }

    private func point(for index: Int, size: CGSize) -> CGPoint {
        guard entries.count > 1, values.indices.contains(index) else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let x = CGFloat(index) / CGFloat(entries.count - 1) * (size.width - 32) + 16
        let value = values[index]
        let percent = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let y = size.height - 24 - CGFloat(percent) * (size.height - 48)
        return CGPoint(x: x, y: y)
    }

    private func linePath(in size: CGSize) -> Path {
        var path = Path()
        guard !entries.isEmpty else { return path }

        path.move(to: point(for: 0, size: size))
        for index in entries.indices.dropFirst() {
            path.addLine(to: point(for: index, size: size))
        }
        return path
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()
        for step in 1...3 {
            let y = size.height * CGFloat(step) / 4
            path.move(to: CGPoint(x: 12, y: y))
            path.addLine(to: CGPoint(x: size.width - 12, y: y))
        }
        return path
    }

    private func referenceBand(in size: CGSize) -> Path {
        var path = Path()
        let rect = CGRect(x: 16, y: size.height * 0.28, width: size.width - 32, height: size.height * 0.34)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 14, height: 14))
        return path
    }

    @ViewBuilder
    private func points(in size: CGSize) -> some View {
        ForEach(entries.indices, id: \.self) { index in
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 13, height: 13)
                .overlay(Circle().stroke(Color.growth, lineWidth: 3))
                .position(point(for: index, size: size))
        }
    }
}

private struct GrowthHistory: View {
    @EnvironmentObject private var store: BabyHealthStore
    var profile: BabyProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Measurement log")

            let entries = store.growthEntries(for: profile).reversed()
            if entries.isEmpty {
                EmptyState(icon: "ruler", title: "No growth data", subtitle: "Add weight, height, and head circumference after a checkup.")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(entries)) { entry in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppFormatters.shortDate.string(from: entry.date))
                                    .font(.rounded(14, weight: .bold))
                                Text(entry.notes.isEmpty ? "Measurement" : entry.notes)
                                    .font(.rounded(12))
                                    .foregroundStyle(Color.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(String(format: "%.1f kg", entry.weightKg))
                                Text(String(format: "%.0f cm / %.1f cm", entry.heightCm, entry.headCircumferenceCm))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .font(.rounded(12, weight: .semibold))
                        }
                        .padding(12)
                        .appCard(radius: 14)
                    }
                }
            }
        }
    }
}
