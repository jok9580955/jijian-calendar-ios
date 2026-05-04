import Foundation
import SwiftData
import SwiftUI

enum CalendarItemKind: String, Codable, CaseIterable, Identifiable {
    case schedule
    case plan
    case birthday
    case anniversary
    case countdown

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .schedule: "Schedule"
        case .plan: "Plan"
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .countdown: "Countdown"
        }
    }

    var symbolName: String {
        switch self {
        case .schedule: "calendar.badge.clock"
        case .plan: "checklist"
        case .birthday: "birthday.cake"
        case .anniversary: "heart"
        case .countdown: "hourglass"
        }
    }
}

enum RepeatCadence: String, Codable, CaseIterable, Identifiable {
    case never
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .never: "Never"
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

enum ReminderLeadTime: Int, Codable, CaseIterable, Identifiable {
    case none = -1
    case atTime = 0
    case fiveMinutes = 5
    case fifteenMinutes = 15
    case oneHour = 60
    case oneDay = 1440
    case oneWeek = 10080

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .none: "No reminder"
        case .atTime: "At time"
        case .fiveMinutes: "5 minutes before"
        case .fifteenMinutes: "15 minutes before"
        case .oneHour: "1 hour before"
        case .oneDay: "1 day before"
        case .oneWeek: "1 week before"
        }
    }
}

@Model
final class CalendarItem: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var kindRaw: String = CalendarItemKind.schedule.rawValue
    var startDate: Date = Date()
    var endDate: Date?
    var isAllDay: Bool = true
    var repeatRaw: String = RepeatCadence.never.rawValue
    var reminderMinutesBefore: Int = ReminderLeadTime.none.rawValue
    var accentHex: String = "#FF5A7A"
    var symbolName: String = CalendarItemKind.schedule.symbolName
    var isPinned: Bool = false
    var externalCalendarIdentifier: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        kind: CalendarItemKind,
        startDate: Date,
        endDate: Date? = nil,
        isAllDay: Bool = true,
        repeatCadence: RepeatCadence = .never,
        reminder: ReminderLeadTime = .none,
        accentHex: String = "#FF5A7A",
        symbolName: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.kindRaw = kind.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.repeatRaw = repeatCadence.rawValue
        self.reminderMinutesBefore = reminder.rawValue
        self.accentHex = accentHex
        self.symbolName = symbolName ?? kind.symbolName
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var kind: CalendarItemKind {
        get { CalendarItemKind(rawValue: kindRaw) ?? .schedule }
        set {
            kindRaw = newValue.rawValue
            symbolName = newValue.symbolName
            updatedAt = Date()
        }
    }

    var repeatCadence: RepeatCadence {
        get { RepeatCadence(rawValue: repeatRaw) ?? .never }
        set {
            repeatRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var reminderLeadTime: ReminderLeadTime {
        ReminderLeadTime(rawValue: reminderMinutesBefore) ?? .none
    }

    func daysUntil(from date: Date = Date(), calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let target = calendar.startOfDay(for: startDate)
        return calendar.dateComponents([.day], from: start, to: target).day ?? 0
    }

    func occurs(on date: Date, calendar: Calendar = .current) -> Bool {
        switch repeatCadence {
        case .never:
            if let endDate {
                return date >= calendar.startOfDay(for: startDate) && date <= calendar.startOfDay(for: endDate)
            }
            return calendar.isDate(date, inSameDayAs: startDate)
        case .daily:
            return date >= calendar.startOfDay(for: startDate)
        case .weekly:
            return calendar.component(.weekday, from: date) == calendar.component(.weekday, from: startDate)
        case .monthly:
            return calendar.component(.day, from: date) == calendar.component(.day, from: startDate)
        case .yearly:
            return calendar.component(.month, from: date) == calendar.component(.month, from: startDate)
                && calendar.component(.day, from: date) == calendar.component(.day, from: startDate)
        }
    }
}

@Model
final class DateBadge: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String = ""
    var colorHex: String = "#00A889"
    var symbolName: String = "tag"
    var createdAt: Date = Date()

    init(date: Date, title: String, colorHex: String = "#00A889", symbolName: String = "tag") {
        self.id = UUID()
        self.date = date
        self.title = title
        self.colorHex = colorHex
        self.symbolName = symbolName
        self.createdAt = Date()
    }
}

@Model
final class HolidayEntry: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var name: String = ""
    var countryCode: String = ""
    var localeIdentifier: String = ""
    var isWorkingDay: Bool = false
    var isAdjustedRestDay: Bool = false

    init(date: Date, name: String, countryCode: String, localeIdentifier: String, isWorkingDay: Bool = false, isAdjustedRestDay: Bool = false) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.countryCode = countryCode
        self.localeIdentifier = localeIdentifier
        self.isWorkingDay = isWorkingDay
        self.isAdjustedRestDay = isAdjustedRestDay
    }
}

@Model
final class ThemePreset: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var accentHex: String = "#FF5A7A"
    var secondaryHex: String = "#00A889"
    var fontDesignRaw: String = "rounded"
    var isSelected: Bool = false

    init(name: String, accentHex: String, secondaryHex: String, fontDesignRaw: String = "rounded", isSelected: Bool = false) {
        self.id = UUID()
        self.name = name
        self.accentHex = accentHex
        self.secondaryHex = secondaryHex
        self.fontDesignRaw = fontDesignRaw
        self.isSelected = isSelected
    }
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let lunarText: String
    let holidays: [HolidaySnapshot]
    let items: [CalendarItem]
    let badges: [DateBadge]
}

struct HolidaySnapshot: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let name: String
    let countryCode: String
    let isWorkingDay: Bool
    let isAdjustedRestDay: Bool
}

struct CloudSyncStatus {
    var title: LocalizedStringKey
    var detail: LocalizedStringKey
    var symbolName: String

    static let ready = CloudSyncStatus(
        title: "iCloud sync ready",
        detail: "Private CloudKit sync keeps your calendars available on your devices.",
        symbolName: "icloud"
    )
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch clean.count {
        case 6:
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF
        default:
            red = 255
            green = 90
            blue = 122
        }
        self.init(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}
