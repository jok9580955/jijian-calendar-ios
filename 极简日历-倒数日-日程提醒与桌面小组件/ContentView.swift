import SwiftData
import SwiftUI

enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month
    case week
    case day

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .month: "Month"
        case .week: "Week"
        case .day: "Day"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CalendarItem.startDate) private var items: [CalendarItem]
    @Query(sort: \DateBadge.date) private var badges: [DateBadge]
    @Query(sort: \ThemePreset.name) private var themes: [ThemePreset]

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()
    @State private var displayMode: CalendarDisplayMode = .month
    @State private var kindFilter: CalendarItemKind?
    @State private var searchText = ""
    @State private var isAddingItem = false
    @State private var editingItem: CalendarItem?
    @State private var isAddingBadge = false
    @State private var isShowingSettings = false
    @State private var isShowingImporter = false
    @State private var importText = ""
    @State private var statusMessage: String?
    @StateObject private var eventKit = EventKitSyncService()

    private let holidayProvider = HolidayProvider()
    private let icsService = ICSService()
    private let scheduler = NotificationScheduler()
    private let widgetStore = WidgetSnapshotStore()
    private let isScreenshotMode: Bool

    init() {
        let mode = UserDefaults.standard.integer(forKey: "ScreenshotMode")
        isScreenshotMode = UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") || mode > 0
        let initialMode: CalendarDisplayMode = switch mode {
        case 2: .week
        case 3: .day
        default: .month
        }
        _displayMode = State(initialValue: initialMode)
        if mode > 0, let date = Calendar.current.date(byAdding: .day, value: 21, to: Date()) {
            _selectedDate = State(initialValue: date)
            _displayedMonth = State(initialValue: date)
        }
    }

    var body: some View {
        if isScreenshotMode {
            ScreenshotShowcaseView(mode: max(UserDefaults.standard.integer(forKey: "ScreenshotMode"), 1))
        } else {
            NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    heroHeader
                    modePicker
                    calendarSurface
                    selectedDayAgenda
                    countdownSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(appBackground)
            .navigationTitle("极简日历-倒数日-日程提醒与桌面小组件")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "slider.horizontal.3")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button("All") { kindFilter = nil }
                        ForEach(CalendarItemKind.allCases) { kind in
                            Button {
                                kindFilter = kind
                            } label: {
                                Label(kind.title, systemImage: kind.symbolName)
                            }
                        }
                        Divider()
                        Button {
                            isAddingBadge = true
                        } label: {
                            Label("Add badge", systemImage: "tag")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    Button {
                        isAddingItem = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .searchable(text: $searchText, prompt: "Search schedules, birthdays, countdowns")
            .sheet(isPresented: $isAddingItem) {
                CalendarItemEditorSheet(defaultDate: selectedDate) { item in
                    modelContext.insert(item)
                    try? modelContext.save()
                    widgetStore.save(items: items + [item])
                    Task { await scheduler.schedule(for: item) }
                }
            }
            .sheet(item: $editingItem) { item in
                CalendarItemEditorSheet(defaultDate: item.startDate, editingItem: item) { updatedItem in
                    updatedItem.updatedAt = Date()
                    try? modelContext.save()
                    syncWidget()
                    Task { await scheduler.schedule(for: updatedItem) }
                }
            }
            .sheet(isPresented: $isAddingBadge) {
                DateBadgeSheet(defaultDate: selectedDate) { badge in
                    modelContext.insert(badge)
                    try? modelContext.save()
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView(
                    items: filteredItems,
                    themes: themes,
                    cloudSyncStatus: .ready,
                    eventKit: eventKit,
                    icsExportText: icsService.export(items: items),
                    onImportTap: { isShowingImporter = true },
                    onImportSystemCalendar: importSystemCalendar,
                    onSelectTheme: selectTheme
                )
            }
            .sheet(isPresented: $isShowingImporter) {
                ICSImportSheet(text: $importText) {
                    let imported = icsService.importItems(from: importText)
                    imported.forEach(modelContext.insert)
                    try? modelContext.save()
                    widgetStore.save(items: items + imported)
                    importText = ""
                }
            }
            .alert("Status", isPresented: Binding(
                get: { statusMessage != nil },
                set: { if !$0 { statusMessage = nil } }
            )) {
                Button("OK", role: .cancel) { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
            .onAppear {
                SeedData.installIfNeeded(in: modelContext)
                syncWidget()
            }
            .onChange(of: items.count) { _, _ in
                syncWidget()
            }
            .onChange(of: items.map(\.updatedAt)) { _, _ in
                syncWidget()
            }
        }
        }
    }

    private var appBackground: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color(hex: selectedTheme.secondaryHex).opacity(0.08),
                Color(uiColor: .secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(monthTitle(displayedMonth))
                        .font(.largeTitle.bold())
                    Text("Calendar, countdowns, reminders and widgets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                syncBadge
            }

            HStack(spacing: 10) {
                metricCard(title: "Today", value: "\(items(on: Date()).count)", symbol: "sun.max", tint: Color(hex: selectedTheme.accentHex))
                metricCard(title: "Upcoming", value: "\(upcomingItems.count)", symbol: "bell.badge", tint: Color(hex: selectedTheme.secondaryHex))
                metricCard(title: "Countdowns", value: "\(countdownItems.count)", symbol: "hourglass", tint: .orange)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var syncBadge: some View {
        Label("iCloud", systemImage: "icloud")
            .font(.caption.bold())
            .foregroundStyle(Color(hex: selectedTheme.accentHex))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(hex: selectedTheme.accentHex).opacity(0.12), in: Capsule())
    }

    private var modePicker: some View {
        Picker("Calendar view", selection: $displayMode) {
            ForEach(CalendarDisplayMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var calendarSurface: some View {
        switch displayMode {
        case .month:
            MonthCalendarView(
                displayedMonth: $displayedMonth,
                selectedDate: $selectedDate,
                days: monthDays
            )
        case .week:
            WeekCalendarView(selectedDate: $selectedDate, days: weekDays)
        case .day:
            DayTimelineView(date: selectedDate, items: items(on: selectedDate))
        }
    }

    private var selectedDayAgenda: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Selected day", systemImage: "list.bullet.rectangle")
            selectedDayBadges
            let dayItems = items(on: selectedDate)
            if dayItems.isEmpty {
                EmptyStateView(
                    title: "Nothing scheduled",
                    message: "Add a plan, birthday, anniversary or countdown for this day.",
                    symbolName: "calendar.badge.plus"
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(dayItems) { item in
                        CalendarItemRow(item: item)
                            .onTapGesture {
                                editingItem = item
                            }
                            .contextMenu {
                                Button {
                                    editingItem = item
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                Button {
                                    exportToAppleCalendar(item)
                                } label: {
                                    Label("Export to Apple Calendar", systemImage: "calendar.badge.plus")
                                }
                                Button(role: .destructive) {
                                    delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var selectedDayBadges: some View {
        let dayBadges = badges.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        if !dayBadges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dayBadges) { badge in
                        Label(badge.title, systemImage: badge.symbolName)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(hex: badge.colorHex).opacity(0.14), in: Capsule())
                            .foregroundStyle(Color(hex: badge.colorHex))
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(badge)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Countdowns", systemImage: "hourglass")
            if countdownItems.isEmpty {
                EmptyStateView(title: "No countdowns yet", message: "Track launches, exams, trips and anniversaries.", symbolName: "hourglass.badge.plus")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(countdownItems) { item in
                            CountdownCard(item: item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var monthDays: [CalendarDay] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: displayedMonth)
        let holidays = holidayProvider.holidays(in: displayedMonth)
        return calendar.monthGrid(containing: displayedMonth).map { date in
            CalendarDay(
                date: date,
                isInDisplayedMonth: calendar.component(.month, from: date) == month,
                isToday: calendar.isDateInToday(date),
                lunarText: holidayProvider.solarTerm(on: date) ?? holidayProvider.lunarText(for: date),
                holidays: holidays.filter { calendar.isDate($0.date, inSameDayAs: date) },
                items: items(on: date),
                badges: badges.filter { calendar.isDate($0.date, inSameDayAs: date) }
            )
        }
    }

    private var weekDays: [CalendarDay] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        let dates = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: week.start) }
        return dates.map { date in
            CalendarDay(
                date: date,
                isInDisplayedMonth: true,
                isToday: Calendar.current.isDateInToday(date),
                lunarText: holidayProvider.solarTerm(on: date) ?? holidayProvider.lunarText(for: date),
                holidays: holidayProvider.holidays(in: date).filter { Calendar.current.isDate($0.date, inSameDayAs: date) },
                items: items(on: date),
                badges: badges.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            )
        }
    }

    private var filteredItems: [CalendarItem] {
        items.filter { item in
            let matchesKind = kindFilter.map { $0 == item.kind } ?? true
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.notes.localizedCaseInsensitiveContains(searchText)
            return matchesKind && matchesSearch
        }
    }

    private var upcomingItems: [CalendarItem] {
        let now = Date()
        return filteredItems.filter { $0.startDate >= now }.sorted { $0.startDate < $1.startDate }
    }

    private var countdownItems: [CalendarItem] {
        filteredItems
            .filter { $0.kind == .countdown || $0.kind == .anniversary || $0.kind == .birthday }
            .sorted { abs($0.daysUntil()) < abs($1.daysUntil()) }
    }

    private var selectedTheme: ThemePreset {
        themes.first(where: \.isSelected) ?? ThemePreset(name: "Coral", accentHex: "#FF5A7A", secondaryHex: "#00A889", isSelected: true)
    }

    private func items(on date: Date) -> [CalendarItem] {
        filteredItems.filter { $0.occurs(on: date) }.sorted { $0.startDate < $1.startDate }
    }

    private func delete(_ item: CalendarItem) {
        scheduler.cancel(for: item)
        modelContext.delete(item)
        try? modelContext.save()
        syncWidget()
    }

    private func importSystemCalendar() {
        Task {
            let state = await eventKit.requestAccess()
            guard state == .granted else { return }
            let start = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let end = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            eventKit.importEvents(from: start, to: end).forEach(modelContext.insert)
            try? modelContext.save()
            syncWidget()
        }
    }

    private func exportToAppleCalendar(_ item: CalendarItem) {
        Task {
            let state = await eventKit.requestAccess()
            guard state == .granted else {
                statusMessage = String(localized: "Calendar access denied")
                return
            }
            do {
                try eventKit.export(item)
                try? modelContext.save()
                statusMessage = String(localized: "Exported to Apple Calendar")
            } catch {
                statusMessage = String(localized: "Export failed")
            }
        }
    }

    private func selectTheme(_ theme: ThemePreset) {
        themes.forEach { $0.isSelected = $0.id == theme.id }
        try? modelContext.save()
    }

    private func syncWidget() {
        widgetStore.save(items: items)
    }

    private func monthTitle(_ date: Date) -> String {
        date.formatted(.dateTime.year().month(.wide))
    }

    private func metricCard(title: LocalizedStringKey, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MonthCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    let days: [CalendarDay]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Button("Today") {
                    selectedDate = Date()
                    displayedMonth = Date()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            weekdayHeader

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(days) { day in
                    MonthDayCell(day: day, isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate))
                        .onTapGesture {
                            selectedDate = day.date
                            displayedMonth = day.date
                        }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var weekdayHeader: some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct MonthDayCell: View {
    let day: CalendarDay
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.callout.weight(day.isToday ? .bold : .medium))
                .foregroundStyle(foreground)
                .frame(width: 30, height: 24)
                .background {
                    Capsule().fill(selectionColor)
                }

            Text(day.holidays.first?.name ?? day.lunarText)
                .font(.system(size: 9))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundColor(day.holidays.isEmpty ? .secondary : .red)

            HStack(spacing: 3) {
                ForEach(day.items.prefix(3)) { item in
                    Circle()
                        .fill(Color(hex: item.accentHex))
                        .frame(width: 5, height: 5)
                }
                ForEach(day.badges.prefix(1)) { badge in
                    Image(systemName: badge.symbolName)
                        .font(.system(size: 7))
                        .foregroundStyle(Color(hex: badge.colorHex))
                }
            }
            .frame(height: 8)
        }
        .frame(minHeight: 58)
        .frame(maxWidth: .infinity)
        .opacity(day.isInDisplayedMonth ? 1 : 0.35)
        .contentShape(Rectangle())
    }

    private var foreground: Color {
        if isSelected { return .white }
        if day.isToday { return .red }
        return .primary
    }

    private var selectionColor: Color {
        if isSelected { return .accentColor }
        if day.isToday { return .red.opacity(0.12) }
        return .clear
    }
}

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    let days: [CalendarDay]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Week", systemImage: "calendar")
            HStack(spacing: 8) {
                ForEach(days) { day in
                    Button {
                        selectedDate = day.date
                    } label: {
                        VStack(spacing: 8) {
                            Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption)
                            Text("\(Calendar.current.component(.day, from: day.date))")
                                .font(.headline)
                            Text(day.holidays.first?.name ?? day.lunarText)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? Color.accentColor.opacity(0.18) : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct DayTimelineView: View {
    let date: Date
    let items: [CalendarItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Day", systemImage: "clock")
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(hour):00")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 6) {
                        let hourItems = items.filter { Calendar.current.component(.hour, from: $0.startDate) == hour || $0.isAllDay }
                        if hourItems.isEmpty {
                            Divider()
                        } else {
                            ForEach(hourItems) { item in
                                CalendarItemRow(item: item)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct CalendarItemRow: View {
    let item: CalendarItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbolName)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: item.accentHex), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if item.kind == .countdown || item.kind == .birthday || item.kind == .anniversary {
                Text(countdownText)
                    .font(.caption.bold())
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(hex: item.accentHex).opacity(0.12), in: Capsule())
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var subtitle: String {
        let date = item.startDate.formatted(date: .abbreviated, time: item.isAllDay ? .omitted : .shortened)
        let repeatText = item.repeatCadence == .never ? String(localized: "No repeat") : String(localized: "Repeats")
        return "\(date) · \(repeatText)"
    }

    private var countdownText: String {
        let days = item.daysUntil()
        if days == 0 { return String(localized: "Today") }
        if days > 0 { return "\(days)d" }
        return "+\(abs(days))d"
    }
}

struct CountdownCard: View {
    let item: CalendarItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.symbolName)
                    .foregroundStyle(Color(hex: item.accentHex))
                Spacer()
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .frame(minHeight: 42, alignment: .topLeading)
            Text(countdownLine)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(item.startDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(width: 170, height: 170, alignment: .topLeading)
        .background(Color(hex: item.accentHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var countdownLine: String {
        let days = item.daysUntil()
        if days == 0 { return String(localized: "Today") }
        return "\(days)"
    }
}

struct CalendarItemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let defaultDate: Date
    let onSave: (CalendarItem) -> Void
    private let editingItem: CalendarItem?

    @State private var title = ""
    @State private var notes = ""
    @State private var kind: CalendarItemKind = .schedule
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate = false
    @State private var isAllDay = true
    @State private var repeatCadence: RepeatCadence = .never
    @State private var reminder: ReminderLeadTime = .none
    @State private var accentHex = "#FF5A7A"
    @State private var isPinned = false

    private let palette = ["#FF5A7A", "#00A889", "#3288FF", "#FFB000", "#7C5CFF", "#FF6B35"]

    init(defaultDate: Date, editingItem: CalendarItem? = nil, onSave: @escaping (CalendarItem) -> Void) {
        self.defaultDate = defaultDate
        self.editingItem = editingItem
        self.onSave = onSave
        _title = State(initialValue: editingItem?.title ?? "")
        _notes = State(initialValue: editingItem?.notes ?? "")
        _kind = State(initialValue: editingItem?.kind ?? .schedule)
        _startDate = State(initialValue: editingItem?.startDate ?? defaultDate)
        _endDate = State(initialValue: editingItem?.endDate ?? editingItem?.startDate ?? defaultDate)
        _hasEndDate = State(initialValue: editingItem?.endDate != nil)
        _isAllDay = State(initialValue: editingItem?.isAllDay ?? true)
        _repeatCadence = State(initialValue: editingItem?.repeatCadence ?? .never)
        _reminder = State(initialValue: editingItem?.reminderLeadTime ?? .none)
        _accentHex = State(initialValue: editingItem?.accentHex ?? "#FF5A7A")
        _isPinned = State(initialValue: editingItem?.isPinned ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                    Picker("Type", selection: $kind) {
                        ForEach(CalendarItemKind.allCases) { itemKind in
                            Label(itemKind.title, systemImage: itemKind.symbolName).tag(itemKind)
                        }
                    }
                }

                Section("Date") {
                    Toggle("All day", isOn: $isAllDay)
                    DatePicker("Starts", selection: $startDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    Toggle("End date", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Ends", selection: $endDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                    }
                    Picker("Repeat", selection: $repeatCadence) {
                        ForEach(RepeatCadence.allCases) { cadence in
                            Text(cadence.title).tag(cadence)
                        }
                    }
                    Picker("Reminder", selection: $reminder) {
                        ForEach(ReminderLeadTime.allCases) { leadTime in
                            Text(leadTime.title).tag(leadTime)
                        }
                    }
                }

                Section("Style") {
                    HStack(spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                accentHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if accentHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Toggle("Pin countdown", isOn: $isPinned)
                }
            }
            .navigationTitle(editingItem == nil ? "New item" : "Edit item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? String(localized: "Untitled event") : title
                        if let editingItem {
                            editingItem.title = cleanedTitle
                            editingItem.notes = notes
                            editingItem.kind = kind
                            editingItem.startDate = startDate
                            editingItem.endDate = hasEndDate ? endDate : nil
                            editingItem.isAllDay = isAllDay
                            editingItem.repeatCadence = repeatCadence
                            editingItem.reminderMinutesBefore = reminder.rawValue
                            editingItem.accentHex = accentHex
                            editingItem.symbolName = kind.symbolName
                            editingItem.isPinned = isPinned
                            editingItem.updatedAt = Date()
                            onSave(editingItem)
                        } else {
                            onSave(CalendarItem(
                                title: cleanedTitle,
                                notes: notes,
                                kind: kind,
                                startDate: startDate,
                                endDate: hasEndDate ? endDate : nil,
                                isAllDay: isAllDay,
                                repeatCadence: repeatCadence,
                                reminder: reminder,
                                accentHex: accentHex,
                                symbolName: kind.symbolName,
                                isPinned: isPinned
                            ))
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DateBadgeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let defaultDate: Date
    let onSave: (DateBadge) -> Void

    @State private var title = ""
    @State private var date: Date
    @State private var colorHex = "#00A889"
    @State private var symbolName = "tag.fill"

    private let palette = ["#FF5A7A", "#00A889", "#3288FF", "#FFB000", "#7C5CFF", "#FF6B35"]
    private let symbols = ["tag.fill", "flag.fill", "star.fill", "heart.fill", "gift.fill", "briefcase.fill"]

    init(defaultDate: Date, onSave: @escaping (DateBadge) -> Void) {
        self.defaultDate = defaultDate
        self.onSave = onSave
        _date = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section("Style") {
                    HStack(spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Picker("Icon", selection: $symbolName) {
                        ForEach(symbols, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol).tag(symbol)
                        }
                    }
                }
            }
            .navigationTitle("Add badge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(DateBadge(
                            date: date,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? String(localized: "Badge") : title,
                            colorHex: colorHex,
                            symbolName: symbolName
                        ))
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    let items: [CalendarItem]
    let themes: [ThemePreset]
    let cloudSyncStatus: CloudSyncStatus
    @ObservedObject var eventKit: EventKitSyncService
    let icsExportText: String
    let onImportTap: () -> Void
    let onImportSystemCalendar: () -> Void
    let onSelectTheme: (ThemePreset) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Themes") {
                    ForEach(themes) { theme in
                        Button {
                            onSelectTheme(theme)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: theme.accentHex))
                                    .frame(width: 22, height: 22)
                                Text(theme.name)
                                Spacer()
                                if theme.isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color(hex: theme.accentHex))
                                }
                            }
                        }
                    }
                }

                Section("Sync") {
                    Label {
                        VStack(alignment: .leading) {
                            Text(cloudSyncStatus.title)
                            Text(cloudSyncStatus.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: cloudSyncStatus.symbolName)
                    }

                    Button {
                        onImportSystemCalendar()
                    } label: {
                        Label("Import from Apple Calendar", systemImage: "calendar.badge.plus")
                    }
                    Text("Calendar access: \(eventKit.accessState.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Import and Export") {
                    ShareLink(item: icsExportText) {
                        Label("Export ICS", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        onImportTap()
                    } label: {
                        Label("Paste ICS import", systemImage: "doc.badge.plus")
                    }
                }

                Section("Privacy") {
                    Label("No ads, no account, no third-party analytics", systemImage: "hand.raised")
                    Label("One-time purchase", systemImage: "creditcard")
                    Label("\(items.count) local items", systemImage: "internaldrive")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ICSImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    let onImport: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                Button {
                    onImport()
                    dismiss()
                } label: {
                    Label("Import events", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("ICS Import")
        }
    }
}

struct SectionTitle: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyStateView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbolName: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [CalendarItem.self, DateBadge.self, HolidayEntry.self, ThemePreset.self], inMemory: true)
}
