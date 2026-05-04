import AppIntents
import Foundation

struct OpenCalendarIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Minimal Calendar"
    static var description = IntentDescription("Open the calendar, countdowns, reminders, and widgets dashboard.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenCountdownsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Countdowns"
    static var description = IntentDescription("Jump to countdown days and anniversary reminders.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct JiJianCalendarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCalendarIntent(),
            phrases: [
                "Open \(.applicationName)",
                "Show my calendar in \(.applicationName)"
            ],
            shortTitle: "Open Calendar",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: OpenCountdownsIntent(),
            phrases: [
                "Show countdowns in \(.applicationName)",
                "Open days left in \(.applicationName)"
            ],
            shortTitle: "Countdowns",
            systemImageName: "hourglass"
        )
    }
}
