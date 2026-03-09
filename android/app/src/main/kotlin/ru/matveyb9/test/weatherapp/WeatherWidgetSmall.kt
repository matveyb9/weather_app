package ru.matveyb9.test.weatherapp

import android.content.SharedPreferences
import android.widget.RemoteViews

class WeatherWidgetSmall : BaseWeatherWidget() {
    override val layoutResId: Int = R.layout.weather_widget_small
    override val rootViewId: Int  = R.id.widget_small_root
    override val refreshViewId: Int = R.id.widget_small_refresh

    override fun applyData(views: RemoteViews, prefs: SharedPreferences) {
        views.setImageViewResource(R.id.widget_small_emoji, iconRes(prefs))
        views.setTextViewText(R.id.widget_small_temp,    str(prefs, "wg_temp",    "--"))
        views.setTextViewText(R.id.widget_small_city,    str(prefs, "wg_city",    "Открыть приложение"))
        views.setTextViewText(R.id.widget_small_desc,    str(prefs, "wg_desc",    "Нет данных"))
        views.setTextViewText(R.id.widget_small_updated, str(prefs, "wg_updated", ""))
    }
}
