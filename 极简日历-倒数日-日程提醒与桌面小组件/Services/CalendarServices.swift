import Combine
import EventKit
import Foundation
import SwiftData
import UserNotifications
import WidgetKit

enum AppGroup {
    static let identifier = "group.com.daniao.jijiancalendar"
}

struct HolidayProvider {
    private let calendar = Calendar.current

    func holidays(in month: Date, locale: Locale = .autoupdatingCurrent) -> [HolidaySnapshot] {
        let countryCode = locale.region?.identifier ?? "US"
        let year = calendar.component(.year, from: month)
        var snapshots = commonGlobalHolidays(year: year, countryCode: countryCode)

        switch countryCode {
        case "CN", "HK", "MO", "TW", "SG":
            snapshots += chineseMarketHolidays(year: year, countryCode: countryCode)
        case "JP":
            snapshots += fixed(year: year, countryCode: "JP", [(1, 8, "Coming of Age Day"), (2, 11, "National Foundation Day"), (5, 3, "Constitution Memorial Day"), (11, 3, "Culture Day")])
        case "DE":
            snapshots += fixed(year: year, countryCode: "DE", [(5, 1, "Labour Day"), (10, 3, "German Unity Day"), (12, 26, "Second Christmas Day")])
        case "FR":
            snapshots += fixed(year: year, countryCode: "FR", [(5, 1, "Labour Day"), (7, 14, "Bastille Day"), (11, 11, "Armistice Day")])
        case "GB":
            snapshots += fixed(year: year, countryCode: "GB", [(5, 1, "Early May Bank Holiday"), (12, 26, "Boxing Day")])
        case "BR":
            snapshots += fixed(year: year, countryCode: "BR", [(4, 21, "Tiradentes Day"), (9, 7, "Independence Day"), (11, 15, "Republic Proclamation Day")])
        default:
            snapshots += fixed(year: year, countryCode: countryCode, [(7, 4, "Independence Day"), (11, 11, "Veterans Day"), (11, 28, "Thanksgiving")])
        }

        guard let interval = calendar.dateInterval(of: .month, for: month) else { return snapshots }
        return snapshots
            .filter { interval.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    func lunarText(for date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        let region = locale.region?.identifier ?? "US"
        guard ["CN", "HK", "MO", "TW", "SG"].contains(region) || locale.identifier.hasPrefix("zh") else {
            return dayNumber(for: date)
        }

        var chineseCalendar = Calendar(identifier: .chinese)
        chineseCalendar.locale = Locale(identifier: "zh_Hans")
        let day = chineseCalendar.component(.day, from: date)
        let month = chineseCalendar.component(.month, from: date)

        if day == 1 {
            return "农历\(month)月"
        }
        let names = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
                     "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
                     "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        return names[safe: day - 1] ?? dayNumber(for: date)
    }

    func solarTerm(on date: Date) -> String? {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let terms: [String: String] = [
            "2-4": "立春", "3-5": "惊蛰", "4-5": "清明", "5-5": "立夏", "6-6": "芒种", "7-7": "小暑",
            "8-7": "立秋", "9-7": "白露", "10-8": "寒露", "11-7": "立冬", "12-7": "大雪", "12-22": "冬至"
        ]
        return terms["\(month)-\(day)"]
    }

    private func commonGlobalHolidays(year: Int, countryCode: String) -> [HolidaySnapshot] {
        fixed(year: year, countryCode: countryCode, [
            (1, 1, "New Year"),
            (2, 14, "Valentine's Day"),
            (12, 24, "Christmas Eve"),
            (12, 25, "Christmas")
        ])
    }

    private func chineseMarketHolidays(year: Int, countryCode: String) -> [HolidaySnapshot] {
        var holidays = fixed(year: year, countryCode: countryCode, [
            (1, 1, "元旦"),
            (5, 1, "劳动节"),
            (10, 1, "国庆节"),
            (10, 2, "国庆假期"),
            (10, 3, "国庆假期")
        ])
        holidays += [
            lunarHoliday(year: year, month: 1, day: 1, name: "春节", countryCode: countryCode),
            lunarHoliday(year: year, month: 1, day: 15, name: "元宵节", countryCode: countryCode),
            lunarHoliday(year: year, month: 5, day: 5, name: "端午节", countryCode: countryCode),
            lunarHoliday(year: year, month: 8, day: 15, name: "中秋节", countryCode: countryCode)
        ].compactMap { $0 }
        return holidays
    }

    private func lunarHoliday(year: Int, month: Int, day: Int, name: String, countryCode: String) -> HolidaySnapshot? {
        var chineseCalendar = Calendar(identifier: .chinese)
        chineseCalendar.timeZone = .current
        let components = DateComponents(calendar: chineseCalendar, era: 78, year: year - 2637, month: month, day: day)
        guard let date = chineseCalendar.date(from: components) else { return nil }
        return HolidaySnapshot(date: date, name: name, countryCode: countryCode, isWorkingDay: false, isAdjustedRestDay: false)
    }

    private func fixed(year: Int, countryCode: String, _ values: [(Int, Int, String)]) -> [HolidaySnapshot] {
        values.compactMap { month, day, name in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else { return nil }
            return HolidaySnapshot(date: date, name: name, countryCode: countryCode, isWorkingDay: false, isAdjustedRestDay: false)
        }
    }

    private func dayNumber(for date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }
}

@MainActor
final class NotificationScheduler {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func schedule(for item: CalendarItem) async {
        guard item.reminderMinutesBefore >= 0 else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let alreadyAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        let canSchedule = alreadyAuthorized ? true : await requestAuthorization()
        guard canSchedule else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.notes.isEmpty ? String(localized: "Event is coming up") : item.notes
        content.sound = .default

        let triggerDate = item.startDate.addingTimeInterval(TimeInterval(-item.reminderMinutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: item.repeatCadence != .never)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancel(for item: CalendarItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
}

struct WidgetSnapshotStore {
    private let suite = UserDefaults(suiteName: AppGroup.identifier)

    func save(items: [CalendarItem]) {
        guard let next = items
            .filter({ $0.kind == .countdown || $0.kind == .birthday || $0.kind == .anniversary })
            .sorted(by: { abs($0.daysUntil()) < abs($1.daysUntil()) })
            .first else {
            suite?.removeObject(forKey: "widget.title")
            suite?.removeObject(forKey: "widget.subtitle")
            suite?.removeObject(forKey: "widget.days")
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        suite?.set(next.title, forKey: "widget.title")
        suite?.set(next.startDate.formatted(date: .abbreviated, time: .omitted), forKey: "widget.subtitle")
        suite?.set(next.daysUntil(), forKey: "widget.days")
        WidgetCenter.shared.reloadAllTimelines()
    }
}

@MainActor
final class EventKitSyncService: ObservableObject {
    enum AccessState: String {
        case unknown
        case denied
        case granted
    }

    private let store = EKEventStore()
    @Published private(set) var accessState: AccessState = .unknown

    func requestAccess() async -> AccessState {
        do {
            let granted = try await store.requestFullAccessToEvents()
            accessState = granted ? .granted : .denied
        } catch {
            accessState = .denied
        }
        return accessState
    }

    func importEvents(from start: Date, to end: Date) -> [CalendarItem] {
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map { event in
            CalendarItem(
                id: UUID(),
                title: event.title ?? String(localized: "Untitled event"),
                notes: event.notes ?? "",
                kind: .schedule,
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                repeatCadence: event.hasRecurrenceRules ? .weekly : .never,
                reminder: .none,
                accentHex: "#3288FF",
                symbolName: "calendar",
                isPinned: false
            )
        }
    }

    func export(_ item: CalendarItem) throws {
        let event = EKEvent(eventStore: store)
        event.title = item.title
        event.notes = item.notes
        event.startDate = item.startDate
        event.endDate = item.endDate ?? item.startDate.addingTimeInterval(item.isAllDay ? 86_400 : 3_600)
        event.isAllDay = item.isAllDay
        event.calendar = store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent)
        item.externalCalendarIdentifier = event.eventIdentifier
    }
}

struct ICSService {
    func export(items: [CalendarItem]) -> String {
        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//JiJianCalendar//Global//EN"
        ]
        for item in items {
            lines += [
                "BEGIN:VEVENT",
                "UID:\(item.id.uuidString)",
                "DTSTAMP:\(icsDate(Date()))",
                "DTSTART:\(icsDate(item.startDate))",
                "SUMMARY:\(escape(item.title))",
                "DESCRIPTION:\(escape(item.notes))",
                "END:VEVENT"
            ]
        }
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\r\n")
    }

    func importItems(from text: String) -> [CalendarItem] {
        text.components(separatedBy: "BEGIN:VEVENT")
            .dropFirst()
            .compactMap { block in
                let fields = Dictionary(uniqueKeysWithValues: block
                    .components(separatedBy: .newlines)
                    .compactMap { line -> (String, String)? in
                        guard let separator = line.firstIndex(of: ":") else { return nil }
                        let key = String(line[..<separator])
                        let value = String(line[line.index(after: separator)...])
                        return (key, value)
                    })
                guard let title = fields["SUMMARY"], let dateString = fields["DTSTART"], let date = parseICSDate(dateString) else {
                    return nil
                }
                return CalendarItem(
                    title: title.replacingOccurrences(of: "\\,", with: ","),
                    notes: fields["DESCRIPTION"] ?? "",
                    kind: .schedule,
                    startDate: date,
                    isAllDay: false,
                    repeatCadence: .never,
                    reminder: .none,
                    accentHex: "#3288FF"
                )
            }
    }

    private func icsDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.string(from: date)
    }

    private func parseICSDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter.date(from: value)
    }

    private func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

extension Calendar {
    func monthGrid(containing date: Date) -> [Date] {
        guard let monthInterval = dateInterval(of: .month, for: date),
              let firstWeek = dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        var days: [Date] = []
        var current = firstWeek.start
        for _ in 0..<42 {
            days.append(current)
            current = self.date(byAdding: .day, value: 1, to: current) ?? current
        }
        return days
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
