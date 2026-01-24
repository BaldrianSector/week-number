import AppKit
import SwiftUI

@main
struct WeekNumberMenuBarApp: App {
    var body: some Scene {
        MenuBarExtra {
            WeekMenuContent()
        } label: {
            WeekMenuLabel()
        }
        .menuBarExtraStyle(.menu)
    }
}

enum WeekNumberProvider {
    static func weekInfo(for date: Date, useISOWeek: Bool) -> (week: Int, year: Int) {
        let calendar = useISOWeek ? Calendar(identifier: .iso8601) : Calendar.current
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.yearForWeekOfYear, from: date)
        return (week, year)
    }

    static func totalWeeks(for date: Date, useISOWeek: Bool) -> Int {
        let calendar = useISOWeek ? Calendar(identifier: .iso8601) : Calendar.current
        let weekYear = calendar.component(.yearForWeekOfYear, from: date)
        var nextYearStart = DateComponents()
        nextYearStart.yearForWeekOfYear = weekYear + 1
        nextYearStart.weekOfYear = 1
        nextYearStart.weekday = calendar.firstWeekday
        guard let startNextWeekYear = calendar.date(from: nextYearStart),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: startNextWeekYear) else {
            return 52
        }
        return calendar.component(.weekOfYear, from: lastDay)
    }
}

private struct WeekMenuLabel: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60 * 60, on: .main, in: .common).autoconnect()
    @AppStorage("labelStyle") private var labelStyleRaw = WeekLabelStyle.week.rawValue
    @AppStorage("useISOWeek") private var useISOWeek = true
    @AppStorage("twoDigitWeek") private var twoDigitWeek = false

    var body: some View {
        let info = WeekNumberProvider.weekInfo(for: now, useISOWeek: useISOWeek)
        let labelStyle = WeekLabelStyle(rawValue: labelStyleRaw) ?? .week
        let totalWeeks = WeekNumberProvider.totalWeeks(for: now, useISOWeek: useISOWeek)
        let minWeekDigits = twoDigitWeek ? 2 : 1
        Text(labelStyle.labelText(week: info.week, year: info.year, totalWeeks: totalWeeks, minWeekDigits: minWeekDigits))
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.primary)
            .monospacedDigit()
            .onReceive(timer) { now = $0 }
    }
}

private struct WeekMenuContent: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 60 * 60, on: .main, in: .common).autoconnect()
    @AppStorage("labelStyle") private var labelStyleRaw = WeekLabelStyle.week.rawValue
    @AppStorage("useISOWeek") private var useISOWeek = true
    @AppStorage("twoDigitWeek") private var twoDigitWeek = false

    var body: some View {
        let info = WeekNumberProvider.weekInfo(for: now, useISOWeek: useISOWeek)
        let totalWeeks = WeekNumberProvider.totalWeeks(for: now, useISOWeek: useISOWeek)
        let minWeekDigits = twoDigitWeek ? 2 : 1
        Divider()
        Picker("Label Style", selection: $labelStyleRaw) {
            ForEach(WeekLabelStyle.allCases) { style in
                Text(style.labelText(week: info.week, year: info.year, totalWeeks: totalWeeks, minWeekDigits: minWeekDigits))
                    .tag(style.rawValue)
            }
        }
        Toggle("Two-digit Format", isOn: $twoDigitWeek)
        Toggle("Use ISO Week (Mon start)", isOn: $useISOWeek)
        Divider()
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .onReceive(timer) { now = $0 }
    }
}

private enum WeekLabelStyle: String, CaseIterable, Identifiable {
    case number
    case short
    case fraction
    case week
    case weekCaps
    case iso

    var id: String { rawValue }

    func labelText(week: Int, year: Int, totalWeeks: Int, minWeekDigits: Int) -> String {
        let weekString = formatWeek(week, minDigits: minWeekDigits)
        switch self {
        case .number:
            return weekString
        case .short:
            return "W \(weekString)"
        case .fraction:
            return "\(weekString)/\(totalWeeks)"
        case .week:
            return "Week \(weekString)"
        case .weekCaps:
            return "WEEK \(weekString)"
        case .iso:
            return "\(year)-W\(weekString)"
        }
    }
}

private func formatWeek(_ week: Int, minDigits: Int) -> String {
    let digits = max(1, minDigits)
    return String(format: "%0*d", digits, week)
}
