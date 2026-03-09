// ios/Runner/AppDelegate.swift

import UIKit
import Flutter
import home_widget
import BackgroundTasks
import WidgetKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private let bgTaskId = "ru.matveyb9.test.weatherapp.weatherRefresh"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        HomeWidgetPlugin.setAppGroupId("group.ru.matveyb9.test.weatherapp")
        GeneratedPluginRegistrant.register(with: self)

        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: bgTaskId, using: nil
            ) { [weak self] task in
                self?.handleWeatherRefresh(task: task as! BGAppRefreshTask)
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Background refresh

    @available(iOS 13.0, *)
    private func handleWeatherRefresh(task: BGAppRefreshTask) {
        scheduleWeatherRefresh()

        let ud   = UserDefaults(suiteName: "group.ru.matveyb9.test.weatherapp")
        let city = ud?.string(forKey: "bg_city") ?? ""
        let lat  = Double(ud?.string(forKey: "bg_lat") ?? "") ?? 0.0
        let lon  = Double(ud?.string(forKey: "bg_lon") ?? "") ?? 0.0

        guard !city.isEmpty, lat != 0.0, lon != 0.0 else {
            task.setTaskCompleted(success: true); return
        }

        let urlStr = "https://api.open-meteo.com/v1/forecast"
                   + "?latitude=\(lat)&longitude=\(lon)"
                   + "&current=temperature_2m,weather_code,is_day,apparent_temperature"
                   + "&timezone=auto&forecast_days=1"
        guard let url = URL(string: urlStr) else {
            task.setTaskCompleted(success: false); return
        }

        let dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { task.setTaskCompleted(success: false); return }
            guard let data = data, error == nil,
                  let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any]
            else { task.setTaskCompleted(success: false); return }

            let temp  = Int((current["temperature_2m"] as? Double ?? 0).rounded())
            let code  = current["weather_code"] as? Int ?? 0
            let isDay = (current["is_day"] as? Int ?? 1) == 1

            // Store code + isDay as strings; WeatherWidget.swift reads them
            ud?.set("\(temp)°C",             forKey: "wg_temp")
            ud?.set(city,                    forKey: "wg_city")
            ud?.set(String(code),            forKey: "wg_code")
            ud?.set(isDay ? "1" : "0",       forKey: "wg_isday")
            ud?.set(self.desc(code: code),   forKey: "wg_desc")
            ud?.set(self.timeNow(),          forKey: "wg_updated")
            ud?.synchronize()

            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = { dataTask.cancel() }
        dataTask.resume()
    }

    @available(iOS 13.0, *)
    func scheduleWeatherRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        if #available(iOS 13.0, *) { scheduleWeatherRefresh() }
    }

    // MARK: - Helpers

    private func desc(code: Int) -> String {
        switch code {
        case 0:        return "Ясно"
        case 1:        return "Преимущественно ясно"
        case 2:        return "Переменная облачность"
        case 3:        return "Пасмурно"
        case 45, 48:   return "Туман"
        case 51...55:  return "Морось"
        case 61...65:  return "Дождь"
        case 71...75:  return "Снег"
        case 80...82:  return "Ливень"
        case 95:       return "Гроза"
        case 96, 99:   return "Гроза с градом"
        default:       return "Переменная облачность"
        }
    }

    private func timeNow() -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: Date())
    }
}
