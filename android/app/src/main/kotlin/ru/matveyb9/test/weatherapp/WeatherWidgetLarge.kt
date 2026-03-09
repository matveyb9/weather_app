package ru.matveyb9.test.weatherapp

import android.content.SharedPreferences
import android.widget.RemoteViews

class WeatherWidgetLarge : BaseWeatherWidget() {
    override val layoutResId: Int  = R.layout.weather_widget_large
    override val rootViewId: Int   = R.id.widget_large_root
    override val refreshViewId: Int = R.id.widget_lg_refresh

    private val hourlyIconIds = intArrayOf(R.id.lg_h1_emoji, R.id.lg_h2_emoji, R.id.lg_h3_emoji, R.id.lg_h4_emoji, R.id.lg_h5_emoji)
    private val hourlyTimeIds = intArrayOf(R.id.lg_h1_time,  R.id.lg_h2_time,  R.id.lg_h3_time,  R.id.lg_h4_time,  R.id.lg_h5_time)
    private val hourlyTempIds = intArrayOf(R.id.lg_h1_temp,  R.id.lg_h2_temp,  R.id.lg_h3_temp,  R.id.lg_h4_temp,  R.id.lg_h5_temp)
    private val dailyIconIds  = intArrayOf(R.id.lg_d1_emoji, R.id.lg_d2_emoji, R.id.lg_d3_emoji, R.id.lg_d4_emoji, R.id.lg_d5_emoji)
    private val dailyDayIds   = intArrayOf(R.id.lg_d1_day,   R.id.lg_d2_day,   R.id.lg_d3_day,   R.id.lg_d4_day,   R.id.lg_d5_day)
    private val dailyMaxIds   = intArrayOf(R.id.lg_d1_max,   R.id.lg_d2_max,   R.id.lg_d3_max,   R.id.lg_d4_max,   R.id.lg_d5_max)
    private val dailyMinIds   = intArrayOf(R.id.lg_d1_min,   R.id.lg_d2_min,   R.id.lg_d3_min,   R.id.lg_d4_min,   R.id.lg_d5_min)

    override fun applyData(views: RemoteViews, prefs: SharedPreferences) {
        views.setImageViewResource(R.id.widget_lg_emoji, iconRes(prefs))
        views.setTextViewText(R.id.widget_lg_temp,     str(prefs, "wg_temp",     "--"))
        views.setTextViewText(R.id.widget_lg_city,     str(prefs, "wg_city",     "Открыть приложение"))
        views.setTextViewText(R.id.widget_lg_feels,    str(prefs, "wg_feels",    ""))
        views.setTextViewText(R.id.widget_lg_desc,     str(prefs, "wg_desc",     "Нет данных"))
        views.setTextViewText(R.id.widget_lg_humidity, str(prefs, "wg_humidity", ""))
        views.setTextViewText(R.id.widget_lg_wind,     str(prefs, "wg_wind",     ""))
        views.setTextViewText(R.id.widget_lg_pressure, str(prefs, "wg_pressure", ""))
        views.setTextViewText(R.id.widget_lg_updated,  str(prefs, "wg_updated",  ""))

        for (i in 0..4) {
            val n = i + 1
            val code  = prefs.getString("wg_h${n}_code",  "0")?.toIntOrNull() ?: 0
            val isDay = prefs.getString("wg_h${n}_isday", "1") == "1"
            views.setImageViewResource(hourlyIconIds[i], iconResForCode(code, isDay))
            views.setTextViewText(hourlyTimeIds[i], str(prefs, "wg_h${n}_time", "--"))
            views.setTextViewText(hourlyTempIds[i], str(prefs, "wg_h${n}_temp", "--"))
        }

        for (i in 0..4) {
            val n = i + 1
            val code = prefs.getString("wg_d${n}_code", "0")?.toIntOrNull() ?: 0
            views.setImageViewResource(dailyIconIds[i], iconResForCode(code, true))
            views.setTextViewText(dailyDayIds[i], str(prefs, "wg_d${n}_day", "--"))
            views.setTextViewText(dailyMaxIds[i], str(prefs, "wg_d${n}_max", "--"))
            views.setTextViewText(dailyMinIds[i], str(prefs, "wg_d${n}_min", "--"))
        }
    }
}
