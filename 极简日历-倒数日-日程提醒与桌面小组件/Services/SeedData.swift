import Foundation
import SwiftData

@MainActor
struct SeedData {
    static func installIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<CalendarItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let samples = [
            CalendarItem(
                title: String(localized: "Product launch"),
                notes: String(localized: "Prepare localized screenshots and App Store metadata."),
                kind: .countdown,
                startDate: calendar.date(byAdding: .day, value: 21, to: today) ?? today,
                repeatCadence: .never,
                reminder: .oneDay,
                accentHex: "#FF5A7A",
                isPinned: true
            ),
            CalendarItem(
                title: String(localized: "Weekly planning"),
                notes: String(localized: "Review this week, schedule important reminders."),
                kind: .plan,
                startDate: next(hour: 9, minute: 30, weekday: 2),
                isAllDay: false,
                repeatCadence: .weekly,
                reminder: .fifteenMinutes,
                accentHex: "#00A889"
            ),
            CalendarItem(
                title: String(localized: "Family birthday"),
                notes: String(localized: "Add a gift note and yearly reminder."),
                kind: .birthday,
                startDate: calendar.date(byAdding: .month, value: 2, to: today) ?? today,
                repeatCadence: .yearly,
                reminder: .oneWeek,
                accentHex: "#FFB000"
            )
        ]
        samples.forEach(context.insert)
        context.insert(DateBadge(date: today, title: String(localized: "Today focus"), colorHex: "#7C5CFF", symbolName: "flag.fill"))
        context.insert(ThemePreset(name: String(localized: "Coral"), accentHex: "#FF5A7A", secondaryHex: "#00A889", isSelected: true))
        context.insert(ThemePreset(name: String(localized: "Ocean"), accentHex: "#3288FF", secondaryHex: "#FFB000"))
        try? context.save()
    }

    private static func next(hour: Int, minute: Int, weekday: Int) -> Date {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return Calendar.current.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
    }
}
