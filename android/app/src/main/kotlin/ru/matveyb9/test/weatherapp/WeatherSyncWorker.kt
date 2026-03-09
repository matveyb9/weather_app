// android/app/.../WeatherSyncWorker.kt
//
// Kotlin WorkManager worker — refreshes widget data when the Flutter Dart
// isolate cannot start (e.g. immediately after reboot, or from widget button).
// Fetches current + hourly + daily from Open-Meteo and saves all widget keys.

package ru.matveyb9.test.weatherapp

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.URL
import java.util.Calendar

class WeatherSyncWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    companion object {
        private const val TAG      = "WeatherSyncWorker"
        private const val BASE_URL = "https://api.open-meteo.com/v1/forecast"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val prefs = HomeWidgetPlugin.getData(applicationContext)
            val lat   = prefs.getString("bg_lat",  null)?.toDoubleOrNull()
            val lon   = prefs.getString("bg_lon",  null)?.toDoubleOrNull()
            val city  = prefs.getString("bg_city", null)

            if (lat == null || lon == null || city == null) {
                Log.d(TAG, "No saved location — skipping")
                return@withContext Result.success()
            }

            Log.d(TAG, "Syncing for $city ($lat, $lon)")
            val json = URL(buildUrl(lat, lon)).readText()
            val root = JSONObject(json)

            val editor = prefs.edit()

            // ── Current ─────────────────────────────────────────────────────
            val cur   = root.getJSONObject("current")
            val temp  = cur.getDouble("temperature_2m").toInt()
            val feels = cur.getDouble("apparent_temperature").toInt()
            val code  = cur.getInt("weather_code")
            val isDay = cur.getInt("is_day") == 1
            val wind  = cur.getDouble("wind_speed_10m").toInt()
            val windDir = cur.getInt("wind_direction_10m")
            val hum   = cur.getInt("relative_humidity_2m")
            val pres  = (cur.getDouble("pressure_msl") * 0.750062).toInt()

            // Read unit preferences saved by Flutter SettingsProvider
            val tempKey  = prefs.getString("settings_temp_unit",     "celsius") ?: "celsius"
            val windKey  = prefs.getString("settings_wind_unit",     "ms")      ?: "ms"
            val pressKey = prefs.getString("settings_pressure_unit", "mmhg")    ?: "mmhg"

            val tempStr  = formatTemp(temp.toDouble(), tempKey)
            val feelsStr = "Ощущается как ${formatTemp(feels.toDouble(), tempKey)}"
            val windStr  = "${formatWind(wind.toDouble(), windKey)} ${windDir(windDir)}"
            val pressStr = formatPressure(cur.getDouble("pressure_msl"), pressKey)

            editor.putString("wg_city",     city)
            editor.putString("wg_temp",     tempStr)
            editor.putString("wg_feels",    feelsStr)
            editor.putString("wg_desc",     descForCode(code))
            editor.putString("wg_code",     code.toString())
            editor.putString("wg_isday",    if (isDay) "1" else "0")
            editor.putString("wg_humidity", "$hum%")
            editor.putString("wg_wind",     windStr)
            editor.putString("wg_pressure", pressStr)
            editor.putString("wg_updated",  currentTime())

            // ── Hourly (5 slots) ─────────────────────────────────────────────
            val hourly = root.getJSONObject("hourly")
            val hTimes = hourly.getJSONArray("time")
            val hTemps = hourly.getJSONArray("temperature_2m")
            val hCodes = hourly.getJSONArray("weather_code")
            val hIsDay = hourly.getJSONArray("is_day")

            // Find index of current hour
            val nowHour = Calendar.getInstance().let { cal ->
                String.format("%04d-%02d-%02dT%02d:00",
                    cal.get(Calendar.YEAR),
                    cal.get(Calendar.MONTH) + 1,
                    cal.get(Calendar.DAY_OF_MONTH),
                    cal.get(Calendar.HOUR_OF_DAY))
            }
            var startIdx = 0
            for (i in 0 until hTimes.length()) {
                if (hTimes.getString(i) == nowHour) { startIdx = i; break }
            }

            for (slot in 0 until 5) {
                val idx = startIdx + slot
                val pfx = "wg_h${slot + 1}"
                if (idx < hTimes.length()) {
                    val timeStr = hTimes.getString(idx).substring(11, 16) // "HH:mm"
                    editor.putString("${pfx}_time",  if (slot == 0) "Сейчас" else timeStr)
                    editor.putString("${pfx}_temp",  "${formatTempShort(hTemps.getDouble(idx), tempKey)}")
                    editor.putString("${pfx}_code",  hCodes.getInt(idx).toString())
                    editor.putString("${pfx}_isday", if (hIsDay.getInt(idx) == 1) "1" else "0")
                } else {
                    editor.putString("${pfx}_time", ""); editor.putString("${pfx}_temp", "")
                    editor.putString("${pfx}_code", "0"); editor.putString("${pfx}_isday", "1")
                }
            }

            // ── Daily (5 days) ───────────────────────────────────────────────
            val daily  = root.getJSONObject("daily")
            val dDates = daily.getJSONArray("time")
            val dMax   = daily.getJSONArray("temperature_2m_max")
            val dMin   = daily.getJSONArray("temperature_2m_min")
            val dCodes = daily.getJSONArray("weather_code")
            val dayNames = arrayOf("Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб")

            for (slot in 0 until minOf(5, dDates.length())) {
                val pfx = "wg_d${slot + 1}"
                val dateStr = dDates.getString(slot) // "YYYY-MM-DD"
                val dayLabel = if (slot == 0) "Сег." else {
                    // Parse day-of-week from date string
                    val cal = Calendar.getInstance()
                    val parts = dateStr.split("-")
                    cal.set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt())
                    dayNames[cal.get(Calendar.DAY_OF_WEEK) - 1]
                }
                editor.putString("${pfx}_day",  dayLabel)
                editor.putString("${pfx}_code", dCodes.getInt(slot).toString())
                editor.putString("${pfx}_max",  formatTempShort(dMax.getDouble(slot), tempKey))
                editor.putString("${pfx}_min",  formatTempShort(dMin.getDouble(slot), tempKey))
            }

            editor.apply()
            triggerWidgetUpdate()

            Log.d(TAG, "Sync complete ✓ $city ${temp}°C code=$code")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Sync failed", e)
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }

    private fun buildUrl(lat: Double, lon: Double): String =
        "$BASE_URL?latitude=$lat&longitude=$lon" +
        "&current=temperature_2m,apparent_temperature,weather_code,is_day," +
        "wind_speed_10m,wind_direction_10m,relative_humidity_2m,pressure_msl" +
        "&hourly=temperature_2m,weather_code,is_day" +
        "&daily=temperature_2m_max,temperature_2m_min,weather_code" +
        "&timezone=auto&forecast_days=2&forecast_hours=25&wind_speed_unit=kmh"

    private fun currentTime(): String {
        val cal = Calendar.getInstance()
        return String.format("%02d:%02d",
            cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE))
    }

    private fun triggerWidgetUpdate() {
        val ctx = applicationContext
        val mgr = AppWidgetManager.getInstance(ctx)
        for (cls in listOf(
            WeatherWidgetSmall::class.java,
            WeatherWidgetMedium::class.java,
            WeatherWidgetLarge::class.java
        )) {
            val ids = mgr.getAppWidgetIds(ComponentName(ctx, cls))
            if (ids.isNotEmpty()) {
                ctx.sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    component = ComponentName(ctx, cls)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                })
            }
        }
    }

    private fun formatTemp(celsius: Double, unit: String): String {
        val v = if (unit == "fahrenheit") celsius * 9 / 5 + 32 else celsius
        return "${v.toInt()}${if (unit == "fahrenheit") "°F" else "°C"}"
    }

    private fun formatTempShort(celsius: Double, unit: String): String {
        val v = if (unit == "fahrenheit") celsius * 9 / 5 + 32 else celsius
        return "${v.toInt()}°"
    }

    private fun formatWind(kmh: Double, unit: String): String = when (unit) {
        "ms"  -> { val v = kmh / 3.6; if (v < 10) "${"%.1f".format(v)} м/с" else "${v.toInt()} м/с" }
        "mph" -> "${(kmh / 1.60934).toInt()} mph"
        else  -> "${kmh.toInt()} км/ч"
    }

    private fun formatPressure(hpa: Double, unit: String): String = when (unit) {
        "mmhg" -> "${(hpa * 0.750062).toInt()} мм рт.ст."
        else   -> "${hpa.toInt()} гПа"
    }

    private fun windDir(deg: Int): String {
        val dirs = arrayOf("С","СВ","В","ЮВ","Ю","ЮЗ","З","СЗ")
        return dirs[((deg + 22.5) / 45).toInt() % 8]
    }

    private fun descForCode(code: Int): String = when (code) {
        0         -> "Ясно"
        1         -> "Преимущественно ясно"
        2         -> "Переменная облачность"
        3         -> "Пасмурно"
        45, 48    -> "Туман"
        in 51..55 -> "Морось"
        56, 57    -> "Ледяная морось"
        in 61..65 -> "Дождь"
        66, 67    -> "Ледяной дождь"
        in 71..75 -> "Снег"
        77        -> "Снежная крупа"
        in 80..82 -> "Ливень"
        85, 86    -> "Снегопад"
        95        -> "Гроза"
        96, 99    -> "Гроза с градом"
        else      -> "Переменная облачность"
    }
}
