import SwiftUI
import WidgetKit

private enum AppGroup {
    static let identifier = "group.com.daniao.jijiancalendar"
}

struct CalendarWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let days: Int
}

struct CalendarWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalendarWidgetEntry {
        CalendarWidgetEntry(date: Date(), title: "极简日历-倒数日-日程提醒与桌面小组件", subtitle: "Next countdown", days: 21)
    }

    func getSnapshot(in context: Context, completion: @escaping (CalendarWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: AppGroup.identifier)
        let title = defaults?.string(forKey: "widget.title") ?? "极简日历-倒数日-日程提醒与桌面小组件"
        let subtitle = defaults?.string(forKey: "widget.subtitle") ?? "Open the app to manage events"
        let days = defaults?.object(forKey: "widget.days") as? Int ?? 21
        let entry = CalendarWidgetEntry(date: Date(), title: title, subtitle: subtitle, days: days)
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct JiJianCalendarWidgetView: View {
    var entry: CalendarWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                Text(entry.title)
                    .font(.headline)
                Spacer()
            }
            Spacer()
            Text("\(entry.days)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(entry.subtitle)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct JiJianCalendarWidget: Widget {
    let kind = "JiJianCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarWidgetProvider()) { entry in
            JiJianCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("极简日历-倒数日-日程提醒与桌面小组件")
        .description("Countdowns, reminders and today's calendar.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct JiJianCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        JiJianCalendarWidget()
    }
}
