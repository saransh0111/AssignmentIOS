import SwiftUI
import Charts

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable, Hashable {
    let id: String
    let date: Date
    let value: Double
    let fundName: String
    let fundCode: Int

    init(date: Date, value: Double, fundName: String, fundCode: Int) {
        self.date = date
        self.value = value
        self.fundName = fundName
        self.fundCode = fundCode
        self.id = "\(fundCode)-\(date.timeIntervalSince1970)"
    }
}

struct ComparisonScreen: View {
    @StateObject private var viewModel = ComparisonViewModel()
    @State private var selectedDataPoint: ChartDataPoint?
    @State private var plotWidth: CGFloat = 0

    let selectedFunds: [Fund]

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading && viewModel.fundDetails.isEmpty {
                    ProgressView("Loading funds...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            // MARK: - Line Chart
                            if !selectedFunds.isEmpty && hasChartData {
                                chartView
                            } else if !viewModel.isLoading {
                                Text("No chart data available")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }

                            // MARK: - Fund Details
                            ForEach(selectedFunds) { fund in
                                if let detail = viewModel.fundDetails[fund.schemeCode] {
                                    FundDetailView(detail: detail)
                                } else {
                                    ProgressView("Loading \(fund.schemeName)...")
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Compare Funds")
            .task {
                await viewModel.fetchFundDetails(for: selectedFunds)
            }
        }
    }

    // MARK: - Chart Data Validation
    private var hasChartData: Bool {
        selectedFunds.contains { fund in
            if let detail = viewModel.fundDetails[fund.schemeCode] {
                return detail.data.contains { nav in
                    nav.parsedDate != nil && nav.navValue > 0
                }
            }
            return false
        }
    }

    // MARK: - Chart View
    private var chartView: some View {
        VStack(spacing: 16) {
            chartWithInteraction
            chartLegend
        }
    }

    private var chartWithInteraction: some View {
        Chart {
            // For each fund, add a series of LineMarks
            ForEach(selectedFunds) { fund in
                if let detail = viewModel.fundDetails[fund.schemeCode] {
                    let sortedData = getSortedData(for: fund, detail: detail)
                    ForEach(sortedData, id: \.id) { item in
                        createLineMark(for: item)
                    }
                }
            }

            // Selected point indicator (rule + point)
            if let selectedPoint = selectedDataPoint {
                createSelectedPointRuleMark(selectedPoint)
                createSelectedPointMark(selectedPoint)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.secondary.opacity(0.2))
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    .foregroundStyle(.secondary.opacity(0.2))
                AxisTick()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .frame(height: 300)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                handleChartDrag(at: value.location, in: geometry, chartProxy: chartProxy)
                            }
                    )
                    .onAppear {
                        plotWidth = geometry[chartProxy.plotAreaFrame].width
                    }
            }
        }
    }

    private func getSortedData(for fund: Fund, detail: FundDetailsResponse) -> [ChartDataPoint] {
        detail.data
            .compactMap { nav in
                guard let date = nav.parsedDate, nav.navValue > 0 else { return nil }
                return ChartDataPoint(date: date, value: nav.navValue, fundName: fund.schemeName, fundCode: fund.schemeCode)
            }
            .sorted { $0.date < $1.date }
    }

    // NOTE: return type is 'some ChartContent' because modifiers produce opaque ChartContent
    private func createLineMark(for item: ChartDataPoint) -> some ChartContent {
        LineMark(
            x: .value("Date", item.date),
            y: .value("NAV", item.value)
        )
        .foregroundStyle(by: .value("Fund", item.fundName))
        .symbol(Circle().strokeBorder(lineWidth: 1))
        .symbolSize(20)
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 1.5))
    }

    private func createSelectedPointRuleMark(_ selectedPoint: ChartDataPoint) -> some ChartContent {
        RuleMark(x: .value("Selected Date", selectedPoint.date))
            .foregroundStyle(.gray.opacity(0.6))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            .annotation(position: .top, alignment: .center) {
                selectedPointAnnotation(selectedPoint)
            }
    }

    private func createSelectedPointMark(_ selectedPoint: ChartDataPoint) -> some ChartContent {
        PointMark(
            x: .value("Selected Date", selectedPoint.date),
            y: .value("Selected NAV", selectedPoint.value)
        )
        .foregroundStyle(colorForFundCode(selectedPoint.fundCode))
        .symbolSize(60)
    }

    private func selectedPointAnnotation(_ selectedPoint: ChartDataPoint) -> some View {
        VStack(spacing: 4) {
            Text(selectedPoint.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .fontWeight(.medium)
            Text("₹\(String(format: "%.2f", selectedPoint.value))")
                .font(.caption2)
                .fontWeight(.bold)
            Text(selectedPoint.fundName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }

    // MARK: - Chart Gesture Handling
    private func handleChartDrag(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        let frame = geometry[chartProxy.plotAreaFrame]
        let origin = frame.origin
        let relativeLocation = CGPoint(x: location.x - origin.x, y: location.y - origin.y)

        var allPoints: [ChartDataPoint] = []
        for fund in selectedFunds {
            if let detail = viewModel.fundDetails[fund.schemeCode] {
                let sorted = detail.data
                    .compactMap { nav -> ChartDataPoint? in
                        guard let date = nav.parsedDate, nav.navValue > 0 else { return nil }
                        return ChartDataPoint(date: date, value: nav.navValue, fundName: fund.schemeName, fundCode: fund.schemeCode)
                    }
                    .sorted { $0.date < $1.date }
                allPoints.append(contentsOf: sorted)
            }
        }
        guard !allPoints.isEmpty else { return }

        if let dateValue: Date = chartProxy.value(atX: relativeLocation.x) {
            if let closest = allPoints.min(by: { abs($0.date.timeIntervalSince(dateValue)) < abs($1.date.timeIntervalSince(dateValue)) }) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedDataPoint = closest
                }
            }
        }
    }

    // MARK: - Legend & Helpers
    private var chartLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Funds")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: legendColumns, spacing: 8) {
                ForEach(selectedFunds) { fund in
                    if viewModel.fundDetails[fund.schemeCode] != nil {
                        legendItem(for: fund)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var legendColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), alignment: .leading), count: 2)
    }

    private func legendItem(for fund: Fund) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colorForFund(fund))
                .frame(width: 10, height: 10)
            Text(fund.schemeName)
                .font(.caption)
                .lineLimit(2)
                .truncationMode(.tail)
            Spacer()
        }
    }

    private func colorForFund(_ fund: Fund) -> Color {
        let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .teal, .indigo]
        let index = selectedFunds.firstIndex(where: { $0.schemeCode == fund.schemeCode }) ?? 0
        return colors[index % colors.count]
    }

    private func colorForFundCode(_ fundCode: Int) -> Color {
        if let fund = selectedFunds.first(where: { $0.schemeCode == fundCode }) {
            return colorForFund(fund)
        }
        return .gray
    }
}

// MARK: - Fund Detail View
struct FundDetailView: View {
    let detail: FundDetailsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.meta.scheme_name ?? "Unknown Fund")
                .font(.headline)

            Text("\(detail.meta.fund_house ?? "Unknown") • \(detail.meta.scheme_category ?? "Unknown Category")")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let latest = detail.data.first {
                HStack {
                    Text("Latest NAV: ₹\(latest.nav)")
                        .font(.body)
                        .fontWeight(.medium)

                    Spacer()

                    if let date = latest.parsedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Additional stats
            HStack {
                VStack(alignment: .leading) {
                    Text("Data Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(detail.data.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                if let oldest = detail.data.last,
                   let oldestDate = oldest.parsedDate {
                    VStack(alignment: .trailing) {
                        Text("Since")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(oldestDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ComparisonScreen_Previews: PreviewProvider {
    static let sampleFunds: [Fund] = [
        Fund(schemeCode: 100028, schemeName: "Sample Fund 1", isinGrowth: nil, isinDivReinvestment: nil),
        Fund(schemeCode: 100029, schemeName: "Sample Fund 2", isinGrowth: nil, isinDivReinvestment: nil)
    ]

    static var previews: some View {
        ComparisonScreen(selectedFunds: sampleFunds)
    }
}
