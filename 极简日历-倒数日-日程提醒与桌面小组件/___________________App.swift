import SwiftUI
import SwiftData

@main
struct MinimalCalendarGlobalApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            CalendarItem.self,
            DateBadge.self,
            HolidayEntry.self,
            ThemePreset.self
        ])
        let isScreenshotMode = UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
            || UserDefaults.standard.integer(forKey: "ScreenshotMode") > 0

        do {
            if isScreenshotMode {
                let configuration = ModelConfiguration(
                    "JiJianCalendarScreenshotStore",
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                container = try ModelContainer(for: schema, configurations: configuration)
            } else {
                let configuration = ModelConfiguration(
                    "JiJianCalendarStore",
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.daniao.jijiancalendar")
                )
                container = try ModelContainer(for: schema, configurations: configuration)
            }
        } catch {
            let fallback = ModelConfiguration(
                "JiJianCalendarLocalStore",
                schema: schema,
                isStoredInMemoryOnly: isScreenshotMode
            )
            do {
                container = try ModelContainer(for: schema, configurations: fallback)
            } catch {
                fatalError("Unable to create SwiftData container: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
