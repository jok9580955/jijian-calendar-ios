import SwiftUI

struct ScreenshotShowcaseView: View {
    let mode: Int

    private var defaults: UserDefaults { .standard }
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Minimal Calendar"
    }

    private var kicker: String { defaults.string(forKey: "ScreenshotKicker") ?? appName }
    private var headline: String { defaults.string(forKey: "ScreenshotHeadline") ?? "Calendar, countdowns, reminders" }
    private var subhead: String { defaults.string(forKey: "ScreenshotSubhead") ?? "Plan important days in one clean view." }
    private var labelA: String { defaults.string(forKey: "ScreenshotLabelA") ?? "Calendar" }
    private var labelB: String { defaults.string(forKey: "ScreenshotLabelB") ?? "Countdown" }
    private var labelC: String { defaults.string(forKey: "ScreenshotLabelC") ?? "Reminder" }
    private var footer: String { defaults.string(forKey: "ScreenshotFooter") ?? "No ads. No account. Private iCloud sync." }

    var body: some View {
        GeometryReader { proxy in
            let isPad = proxy.size.width > 700
            ZStack {
                background
                VStack(alignment: .leading, spacing: isPad ? 30 : 22) {
                    header(isPad: isPad)
                    Group {
                        switch mode {
                        case 2:
                            countdownSurface(isPad: isPad)
                        case 3:
                            reminderSurface(isPad: isPad)
                        case 4:
                            widgetSurface(isPad: isPad)
                        case 5:
                            privacySurface(isPad: isPad)
                        default:
                            calendarSurface(isPad: isPad)
                        }
                    }
                    Spacer(minLength: 0)
                    footerBar(isPad: isPad)
                }
                .padding(.horizontal, isPad ? 64 : 24)
                .padding(.top, isPad ? 56 : 34)
                .padding(.bottom, isPad ? 42 : 24)
            }
        }
        .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
        .statusBarHidden(true)
    }

    private var isRightToLeft: Bool {
        guard let code = Locale.preferredLanguages.first else { return false }
        return code.hasPrefix("ar") || code.hasPrefix("he")
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.98, blue: 0.95),
                Color(red: 0.93, green: 0.98, blue: 0.99),
                Color(red: 0.98, green: 0.96, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func header(isPad: Bool) -> some View {
        VStack(alignment: .leading, spacing: isPad ? 18 : 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color(hex: "#FF5A7A"), Color(hex: "#00A889")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: isPad ? 60 : 48, height: isPad ? 60 : 48)
                    .overlay {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: isPad ? 28 : 22, weight: .bold))
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 3) {
                    Text(kicker)
                        .font(.system(size: isPad ? 18 : 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#006E68"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text(appName)
                        .font(.system(size: isPad ? 24 : 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.48)
                }
            }

            Text(headline)
                .font(.system(size: isPad ? 58 : 38, weight: .heavy))
                .foregroundStyle(Color(hex: "#17202A"))
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .fixedSize(horizontal: false, vertical: true)

            Text(subhead)
                .font(.system(size: isPad ? 25 : 17, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func calendarSurface(isPad: Bool) -> some View {
        VStack(spacing: isPad ? 20 : 14) {
            HStack {
                metric(labelA, value: "12", symbol: "calendar", color: "#FF5A7A", isPad: isPad)
                metric(labelB, value: "28", symbol: "hourglass", color: "#F59E0B", isPad: isPad)
                metric(labelC, value: "6", symbol: "bell.badge", color: "#00A889", isPad: isPad)
            }
            screenshotCard {
                VStack(spacing: isPad ? 16 : 10) {
                    HStack {
                        Text(monthTitle)
                            .font(.system(size: isPad ? 30 : 22, weight: .bold))
                        Spacer()
                        Image(systemName: "icloud")
                            .font(.system(size: isPad ? 24 : 18, weight: .bold))
                            .foregroundStyle(Color(hex: "#008E8A"))
                    }
                    weekdayHeader(isPad: isPad)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: isPad ? 12 : 8) {
                        ForEach(1...35, id: \.self) { index in
                            dayCell(index: index, isPad: isPad)
                        }
                    }
                }
            }
        }
    }

    private func countdownSurface(isPad: Bool) -> some View {
        VStack(spacing: isPad ? 18 : 12) {
            ForEach(countdownRows(isPad: isPad)) { row in
                screenshotCard {
                    HStack(spacing: isPad ? 20 : 14) {
                        Image(systemName: row.symbol)
                            .font(.system(size: isPad ? 34 : 24, weight: .bold))
                            .frame(width: isPad ? 64 : 48, height: isPad ? 64 : 48)
                            .foregroundStyle(Color(hex: row.color))
                            .background(Color(hex: row.color).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(row.title)
                                .font(.system(size: isPad ? 28 : 20, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Text(row.detail)
                                .font(.system(size: isPad ? 18 : 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Text(row.days)
                            .font(.system(size: isPad ? 42 : 30, weight: .heavy))
                            .foregroundStyle(Color(hex: row.color))
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private func reminderSurface(isPad: Bool) -> some View {
        screenshotCard {
            VStack(alignment: .leading, spacing: isPad ? 22 : 16) {
                ForEach(Array(timelineRows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .top, spacing: isPad ? 18 : 12) {
                        VStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: row.color))
                                .frame(width: isPad ? 18 : 14, height: isPad ? 18 : 14)
                            if index < timelineRows.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: row.color).opacity(0.2))
                                    .frame(width: 3, height: isPad ? 58 : 44)
                            }
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(row.time)
                                .font(.system(size: isPad ? 17 : 13, weight: .bold))
                                .foregroundStyle(Color(hex: row.color))
                            Text(row.title)
                                .font(.system(size: isPad ? 27 : 19, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.55)
                            Text(row.detail)
                                .font(.system(size: isPad ? 17 : 13, weight: .medium))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private func widgetSurface(isPad: Bool) -> some View {
        VStack(spacing: isPad ? 20 : 14) {
            HStack(spacing: isPad ? 20 : 14) {
                widgetCard(symbol: "calendar", title: labelA, value: "3", color: "#FF5A7A", isPad: isPad)
                widgetCard(symbol: "hourglass", title: labelB, value: "18", color: "#F59E0B", isPad: isPad)
            }
            HStack(spacing: isPad ? 20 : 14) {
                widgetCard(symbol: "bell.badge", title: labelC, value: "09:30", color: "#00A889", isPad: isPad)
                widgetCard(symbol: "sparkles", title: footer, value: "iCloud", color: "#5570FF", isPad: isPad)
            }
        }
    }

    private func privacySurface(isPad: Bool) -> some View {
        screenshotCard {
            VStack(alignment: .leading, spacing: isPad ? 24 : 18) {
                privacyRow(symbol: "hand.raised", title: labelA, color: "#00A889", isPad: isPad)
                privacyRow(symbol: "icloud", title: labelB, color: "#5570FF", isPad: isPad)
                privacyRow(symbol: "square.and.arrow.down", title: labelC, color: "#FF5A7A", isPad: isPad)
                Divider()
                Text(footer)
                    .font(.system(size: isPad ? 24 : 17, weight: .bold))
                    .foregroundStyle(Color(hex: "#17202A"))
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)
            }
        }
    }

    private func screenshotCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.8), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 16)
    }

    private func metric(_ title: String, value: String, symbol: String, color: String, isPad: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: isPad ? 24 : 18, weight: .bold))
                .foregroundStyle(Color(hex: color))
            Text(value)
                .font(.system(size: isPad ? 34 : 24, weight: .heavy))
                .monospacedDigit()
            Text(title)
                .font(.system(size: isPad ? 16 : 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isPad ? 18 : 12)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
    }

    private func weekdayHeader(isPad: Bool) -> some View {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: isPad ? 15 : 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayCell(index: Int, isPad: Bool) -> some View {
        let active = [8, 14, 16, 21, 28].contains(index)
        let selected = index == 16
        return VStack(spacing: 3) {
            Text("\(index)")
                .font(.system(size: isPad ? 18 : 13, weight: selected ? .heavy : .semibold))
                .monospacedDigit()
            HStack(spacing: 2) {
                Circle().fill(active ? Color(hex: "#FF5A7A") : .clear).frame(width: 4, height: 4)
                Circle().fill(index == 21 ? Color(hex: "#00A889") : .clear).frame(width: 4, height: 4)
            }
        }
        .frame(height: isPad ? 54 : 38)
        .frame(maxWidth: .infinity)
        .foregroundStyle(selected ? .white : .primary)
        .background(selected ? Color(hex: "#FF5A7A") : Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        .opacity(index < 4 || index > 32 ? 0.48 : 1)
    }

    private func widgetCard(symbol: String, title: String, value: String, color: String, isPad: Bool) -> some View {
        screenshotCard {
            VStack(alignment: .leading, spacing: isPad ? 18 : 12) {
                Image(systemName: symbol)
                    .font(.system(size: isPad ? 32 : 24, weight: .bold))
                    .foregroundStyle(Color(hex: color))
                Text(value)
                    .font(.system(size: isPad ? 38 : 28, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(title)
                    .font(.system(size: isPad ? 19 : 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.58)
            }
            .frame(maxWidth: .infinity, minHeight: isPad ? 190 : 128, alignment: .topLeading)
        }
    }

    private func privacyRow(symbol: String, title: String, color: String, isPad: Bool) -> some View {
        HStack(spacing: isPad ? 18 : 12) {
            Image(systemName: symbol)
                .font(.system(size: isPad ? 30 : 22, weight: .bold))
                .foregroundStyle(Color(hex: color))
                .frame(width: isPad ? 58 : 44, height: isPad ? 58 : 44)
                .background(Color(hex: color).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            Text(title)
                .font(.system(size: isPad ? 26 : 18, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
        }
    }

    private func footerBar(isPad: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Color(hex: "#00A889"))
            Text(footer)
                .font(.system(size: isPad ? 18 : 13, weight: .bold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.55)
        }
        .padding(.horizontal, isPad ? 20 : 14)
        .padding(.vertical, isPad ? 14 : 10)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }

    private var monthTitle: String {
        Date().formatted(.dateTime.year().month(.wide))
    }

    private struct CountdownRow: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let days: String
        let symbol: String
        let color: String
    }

    private func countdownRows(isPad: Bool) -> [CountdownRow] {
        [
            CountdownRow(title: labelA, detail: headline, days: "18", symbol: "sparkles", color: "#FF5A7A"),
            CountdownRow(title: labelB, detail: subhead, days: "42", symbol: "airplane.departure", color: "#00A889"),
            CountdownRow(title: labelC, detail: footer, days: "96", symbol: "gift", color: "#F59E0B")
        ]
    }

    private var timelineRows: [(time: String, title: String, detail: String, color: String)] {
        [
            ("09:30", labelA, headline, "#FF5A7A"),
            ("14:00", labelB, subhead, "#00A889"),
            ("20:00", labelC, footer, "#5570FF")
        ]
    }
}

