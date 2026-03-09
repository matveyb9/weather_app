// ios/WeatherWidgetExtension/WeatherWidget.swift
//
// iOS home-screen widgets using WidgetKit + SwiftUI.
// Icons: SF Symbols (iOS 13+).  Refresh: AppIntent Button (iOS 17+)
//   with widgetURL fallback that deep-links the app to run a forced refresh.
//
// ── Setup required in Xcode ───────────────────────────────────────────────────
// 1. File ▸ New ▸ Target ▸ Widget Extension  →  name: WeatherWidgetExtension
// 2. Add App Group to BOTH Runner AND WeatherWidgetExtension:
//       Signing & Capabilities ▸ + ▸ App Groups
//       Add:  group.ru.matveyb9.test.weatherapp
// 3. Drag this file into the WeatherWidgetExtension target.
// ─────────────────────────────────────────────────────────────────────────────

import WidgetKit
import SwiftUI
import AppIntents      // required for AppIntent (iOS 17+)

private let appGroup = "group.ru.matveyb9.test.weatherapp"

// MARK: - Refresh intent (iOS 17+) ────────────────────────────────────────────
// Tapping the refresh button triggers this intent directly — no app launch.
// WidgetCenter.reloadAllTimelines() causes fromDefaults() to re-read UserDefaults
// which will have been updated by the app's background sync shortly after.

@available(iOS 17.0, *)
struct RefreshWeatherIntent: AppIntent {
    static var title: LocalizedStringResource = "Обновить погоду"
    static var description = IntentDescription("Запрашивает свежие данные о погоде.")

    // Tell WidgetKit this intent should be treated as a background action
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        // Signal the app (via UserDefaults App Group) that a refresh was requested
        let ud = UserDefaults(suiteName: appGroup)
        ud?.set(true,        forKey: "wg_refresh_requested")
        ud?.set(Date(),      forKey: "wg_refresh_requested_at")
        ud?.synchronize()

        // Reload widget timelines — the app's next background fetch or
        // the user opening the app will push fresh data
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - SF Symbol mapping ────────────────────────────────────────────────────

func sfSymbol(code: Int, isDay: Bool) -> String {
    switch code {
    case 0, 1:     return isDay ? "sun.max.fill"           : "moon.stars.fill"
    case 2:        return isDay ? "cloud.sun.fill"          : "cloud.moon.fill"
    case 3:        return "cloud.fill"
    case 45, 48:   return "cloud.fog.fill"
    case 51...57:  return "cloud.drizzle.fill"
    case 61...67:  return "cloud.rain.fill"
    case 71...77:  return "snowflake"
    case 80...82:  return "cloud.heavyrain.fill"
    case 85, 86:   return "cloud.snow.fill"
    case 95...99:  return "cloud.bolt.rain.fill"
    default:       return "thermometer.medium"
    }
}

func sfSymbolColor(code: Int, isDay: Bool) -> Color {
    switch code {
    case 0, 1:    return isDay ? Color(red: 1.0, green: 0.78, blue: 0.0)
                               : Color(red: 0.47, green: 0.53, blue: 0.80)
    case 2:       return Color(red: 0.47, green: 0.53, blue: 0.80)
    case 3:       return Color(red: 0.56, green: 0.64, blue: 0.68)
    case 45, 48:  return Color(red: 0.69, green: 0.74, blue: 0.77)
    case 51...57: return Color(red: 0.26, green: 0.65, blue: 0.96)
    case 61...67: return Color(red: 0.12, green: 0.53, blue: 0.90)
    case 71...77: return Color(red: 0.50, green: 0.87, blue: 0.92)
    case 80...82: return Color(red: 0.16, green: 0.71, blue: 0.96)
    case 85, 86:  return Color(red: 0.50, green: 0.83, blue: 0.80)
    case 95...99: return Color(red: 0.49, green: 0.34, blue: 0.76)
    default:      return .white
    }
}

// MARK: - Entry ────────────────────────────────────────────────────────────────

struct WeatherEntry: TimelineEntry {
    let date: Date
    let city: String
    let temp: String
    let sfSym: String
    let symColor: Color
    let desc: String
    let feels: String
    let humidity: String
    let wind: String
    let pressure: String
    let updated: String
    let hourly: [(time: String, sfSym: String, symColor: Color, temp: String)]
    let daily:  [(day: String,  sfSym: String, symColor: Color, max: String, min: String)]

    static func fromDefaults() -> WeatherEntry {
        let ud = UserDefaults(suiteName: appGroup)

        func str(_ key: String, _ fb: String = "—") -> String { ud?.string(forKey: key) ?? fb }
        func intVal(_ key: String) -> Int { Int(ud?.string(forKey: key) ?? "0") ?? 0 }
        func boolVal(_ key: String) -> Bool { (ud?.string(forKey: key) ?? "1") == "1" }

        let code  = intVal("wg_code")
        let isDay = boolVal("wg_isday")

        let hourly = (1...5).map { i -> (String, String, Color, String) in
            let c = intVal("wg_h\(i)_code"); let d = boolVal("wg_h\(i)_isday")
            return (str("wg_h\(i)_time"), sfSymbol(code: c, isDay: d), sfSymbolColor(code: c, isDay: d), str("wg_h\(i)_temp"))
        }
        let daily = (1...5).map { i -> (String, String, Color, String, String) in
            let c = intVal("wg_d\(i)_code")
            return (str("wg_d\(i)_day"), sfSymbol(code: c, isDay: true), sfSymbolColor(code: c, isDay: true), str("wg_d\(i)_max"), str("wg_d\(i)_min"))
        }

        return WeatherEntry(
            date: Date(), city: str("wg_city", "Город"), temp: str("wg_temp", "—°C"),
            sfSym: sfSymbol(code: code, isDay: isDay),
            symColor: sfSymbolColor(code: code, isDay: isDay),
            desc: str("wg_desc", "Загрузка…"), feels: str("wg_feels", ""),
            humidity: str("wg_humidity", "—%"), wind: str("wg_wind", "—"),
            pressure: str("wg_pressure", ""), updated: str("wg_updated", ""),
            hourly: hourly, daily: daily
        )
    }

    static var placeholder: WeatherEntry {
        let h: [(String, String, Color, String)] = [
            ("Сейчас","sun.max.fill",.yellow,"22°"), ("13:00","cloud.sun.fill",.white,"21°"),
            ("14:00","cloud.fill",.gray,"20°"),        ("15:00","cloud.rain.fill",.blue,"18°"),
            ("16:00","cloud.rain.fill",.blue,"17°"),
        ]
        let d: [(String, String, Color, String, String)] = [
            ("Сег.","sun.max.fill",.yellow,"22°","14°"),  ("Пн","cloud.sun.fill",.white,"20°","13°"),
            ("Вт","cloud.fill",.gray,"18°","11°"),          ("Ср","sun.max.fill",.yellow,"24°","15°"),
            ("Чт","cloud.sun.fill",.white,"21°","14°"),
        ]
        return WeatherEntry(
            date: Date(), city: "Москва", temp: "22°C",
            sfSym: "cloud.sun.fill", symColor: .yellow,
            desc: "Переменная облачность", feels: "Ощущается как 20°C",
            humidity: "65%", wind: "12 км/ч С", pressure: "755 мм рт.ст.",
            updated: "12:00", hourly: h, daily: d
        )
    }
}

// MARK: - Provider ─────────────────────────────────────────────────────────────

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry { .placeholder }
    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        completion(WeatherEntry.fromDefaults())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        let entry = WeatherEntry.fromDefaults()
        let next  = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Design tokens ────────────────────────────────────────────────────────

private var widgetGradient: LinearGradient {
    LinearGradient(
        colors: [Color(red: 0.10, green: 0.15, blue: 0.27),
                 Color(red: 0.12, green: 0.23, blue: 0.43),
                 Color(red: 0.08, green: 0.40, blue: 0.75)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Reusable sub-views ───────────────────────────────────────────────────

struct WeatherSymbol: View {
    let name: String; let color: Color; let size: CGFloat
    var body: some View {
        Image(systemName: name)
            .symbolRenderingMode(.multicolor)
            .resizable().scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
    }
}

/// Refresh button — iOS 17+ uses AppIntent (no app launch), older iOS uses widgetURL deep-link.
struct RefreshButton: View {
    var body: some View {
        if #available(iOS 17.0, *) {
            Button(intent: RefreshWeatherIntent()) {
                refreshIcon
            }
            .buttonStyle(.plain)
        } else {
            // iOS 13-16: tapping the widget opens the app via widgetURL; the app
            // reads wg_refresh_requested and triggers a foreground fetch.
            refreshIcon
        }
    }

    private var refreshIcon: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.55))
            .frame(width: 28, height: 28)
            .background(Color.white.opacity(0.10))
            .clipShape(Circle())
    }
}

struct HourCell: View {
    let time: String; let sfSym: String; let symColor: Color; let temp: String
    var body: some View {
        VStack(spacing: 3) {
            Text(time).font(.system(size: 10)).foregroundColor(.white.opacity(0.7))
            WeatherSymbol(name: sfSym, color: symColor, size: 20)
            Text(temp).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DayCell: View {
    let day: String; let sfSym: String; let symColor: Color; let max: String; let min: String
    var body: some View {
        VStack(spacing: 2) {
            Text(day).font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.7))
            WeatherSymbol(name: sfSym, color: symColor, size: 20)
            Text(max).font(.system(size: 12, weight: .bold)).foregroundColor(.white)
            Text(min).font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Small widget ─────────────────────────────────────────────────────────

struct SmallWidgetView: View {
    let entry: WeatherEntry
    var body: some View {
        ZStack(alignment: .topTrailing) {
            widgetGradient
            // Refresh button — top right
            RefreshButton()
                .padding(8)

            VStack(alignment: .leading, spacing: 4) {
                WeatherSymbol(name: entry.sfSym, color: entry.symColor, size: 36)
                Text(entry.temp)
                    .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                Text(entry.city)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9)).lineLimit(1)
                Text(entry.desc)
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                Spacer()
                Text(entry.updated)
                    .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        // widgetURL: fallback for iOS 13-16 — app opens and checks wg_refresh_requested
        .widgetURL(URL(string: "weatherapp://refresh"))
        .containerBackground(widgetGradient, for: .widget)
    }
}

// MARK: - Medium widget ────────────────────────────────────────────────────────

struct MediumWidgetView: View {
    let entry: WeatherEntry
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                WeatherSymbol(name: entry.sfSym, color: entry.symColor, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.city)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.9)).lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(entry.temp)
                            .font(.system(size: 30, weight: .bold)).foregroundColor(.white)
                        Text(entry.feels)
                            .font(.system(size: 11)).foregroundColor(.white.opacity(0.65))
                    }
                    Text(entry.desc)
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.75)).lineLimit(1)
                }
                Spacer()
                // Refresh + timestamp stacked
                VStack(alignment: .trailing, spacing: 2) {
                    RefreshButton()
                    Text(entry.updated)
                        .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                }
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            HStack(spacing: 0) {
                ForEach(Array(entry.hourly.enumerated()), id: \.offset) { _, h in
                    HourCell(time: h.time, sfSym: h.sfSym, symColor: h.symColor, temp: h.temp)
                }
            }
        }
        .padding(14)
        .widgetURL(URL(string: "weatherapp://refresh"))
        .containerBackground(widgetGradient, for: .widget)
    }
}

// MARK: - Large widget ─────────────────────────────────────────────────────────

struct LargeWidgetView: View {
    let entry: WeatherEntry
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                WeatherSymbol(name: entry.sfSym, color: entry.symColor, size: 54)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.temp)
                            .font(.system(size: 38, weight: .bold)).foregroundColor(.white)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(entry.city)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9)).lineLimit(1)
                            Text(entry.feels)
                                .font(.system(size: 11)).foregroundColor(.white.opacity(0.65))
                        }
                    }
                    Text(entry.desc)
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.8))
                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill").font(.system(size: 10))
                            .foregroundColor(Color(red: 0.26, green: 0.65, blue: 0.96))
                        Text(entry.humidity)
                        Text("·").foregroundColor(.white.opacity(0.4))
                        Image(systemName: "wind").font(.system(size: 10))
                            .foregroundColor(Color(red: 0.56, green: 0.64, blue: 0.68))
                        Text(entry.wind)
                        Text("·").foregroundColor(.white.opacity(0.4))
                        Text(entry.pressure)
                    }
                    .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    RefreshButton()
                    Text(entry.updated)
                        .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                }
            }

            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)

            HStack(spacing: 0) {
                ForEach(Array(entry.hourly.enumerated()), id: \.offset) { _, h in
                    HourCell(time: h.time, sfSym: h.sfSym, symColor: h.symColor, temp: h.temp)
                }
            }

            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)

            HStack(spacing: 0) {
                ForEach(Array(entry.daily.enumerated()), id: \.offset) { _, d in
                    DayCell(day: d.day, sfSym: d.sfSym, symColor: d.symColor, max: d.max, min: d.min)
                }
            }
            Spacer()
        }
        .padding(16)
        .widgetURL(URL(string: "weatherapp://refresh"))
        .containerBackground(widgetGradient, for: .widget)
    }
}

// MARK: - Widget configurations ───────────────────────────────────────────────

struct WeatherWidgetSmall: Widget {
    let kind = "WeatherWidgetSmall"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { SmallWidgetView(entry: $0) }
            .configurationDisplayName("Погода — Мини")
            .description("Текущая температура и условия.")
            .supportedFamilies([.systemSmall])
    }
}

struct WeatherWidgetMedium: Widget {
    let kind = "WeatherWidgetMedium"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { MediumWidgetView(entry: $0) }
            .configurationDisplayName("Погода — Почасовой")
            .description("Текущая погода и прогноз на 5 часов.")
            .supportedFamilies([.systemMedium])
    }
}

struct WeatherWidgetLarge: Widget {
    let kind = "WeatherWidgetLarge"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { LargeWidgetView(entry: $0) }
            .configurationDisplayName("Погода — Расширенный")
            .description("Текущая погода, почасовой и 5-дневный прогноз.")
            .supportedFamilies([.systemLarge])
    }
}
