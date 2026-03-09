package ru.matveyb9.test.weatherapp

import android.content.SharedPreferences
import android.widget.RemoteViews

class WeatherWidgetMedium : BaseWeatherWidget() {
    override val layoutResId: Int  = R.layout.weather_widget_medium
    override val rootViewId: Int   = R.id.widget_medium_root
    override val refreshViewId: Int = R.id.widget_med_refresh

    private val hourlyIconIds = intArrayOf(R.id.wg_h1_emoji, R.id.wg_h2_emoji, R.id.wg_h3_emoji, R.id.wg_h4_emoji, R.id.wg_h5_emoji)
    private val hourlyTimeIds = intArrayOf(R.id.wg_h1_time,  R.id.wg_h2_time,  R.id.wg_h3_time,  R.id.wg_h4_time,  R.id.wg_h5_time)
    private val hourlyTempIds = intArrayOf(R.id.wg_h1_temp,  R.id.wg_h2_temp,  R.id.wg_h3_temp,  R.id.wg_h4_temp,  R.id.wg_h5_temp)

    override fun applyData(views: RemoteViews, prefs: SharedPreferences) {
        views.setImageViewResource(R.id.widget_med_emoji, iconRes(prefs))
        views.setTextViewText(R.id.widget_med_temp,    str(prefs, "wg_temp",    "--"))
        views.setTextViewText(R.id.widget_med_city,    str(prefs, "wg_city",    "Открыть приложение"))
        views.setTextViewText(R.id.widget_med_feels,   str(prefs, "wg_feels",   ""))
        views.setTextViewText(R.id.widget_med_desc,    str(prefs, "wg_desc",    "Нет данных"))
        views.setTextViewText(R.id.widget_med_updated, str(prefs, "wg_updated", ""))

        for (i in 0..4) {
            val n = i + 1
            val code  = prefs.getString("wg_h${n}_code",  "0")?.toIntOrNull() ?: 0
            val isDay = prefs.getString("wg_h${n}_isday", "1") == "1"
            views.setImageViewResource(hourlyIconIds[i], iconResForCode(code, isDay))
            views.setTextViewText(hourlyTimeIds[i], str(prefs, "wg_h${n}_time", "--"))
            views.setTextViewText(hourlyTempIds[i], str(prefs, "wg_h${n}_temp", "--"))
        }
    }
}
