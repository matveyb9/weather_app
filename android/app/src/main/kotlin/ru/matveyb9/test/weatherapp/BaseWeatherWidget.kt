package ru.matveyb9.test.weatherapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import androidx.work.*
import es.antonborri.home_widget.HomeWidgetPlugin

abstract class BaseWeatherWidget : AppWidgetProvider() {

    abstract val layoutResId: Int
    abstract val rootViewId: Int
    abstract val refreshViewId: Int
    abstract fun applyData(views: RemoteViews, prefs: SharedPreferences)

    companion object {
        const val ACTION_REFRESH = "ru.matveyb9.test.weatherapp.ACTION_WIDGET_REFRESH"
        private const val TAG = "WeatherWidget"

        /** Redraw all widgets of the given class with current prefs data. */
        fun <T : BaseWeatherWidget> redrawAll(context: Context, widget: T) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, widget::class.java)
            )
            if (ids.isEmpty()) return
            val prefs = HomeWidgetPlugin.getData(context)
            for (id in ids) {
                try {
                    val views = RemoteViews(context.packageName, widget.layoutResId)
                    widget.applyData(views, prefs)
                    widget.setLaunchIntent(context, views)
                    widget.setRefreshIntent(context, views, id)
                    manager.updateAppWidget(id, views)
                } catch (e: Exception) {
                    Log.e(TAG, "redrawAll failed id=$id", e)
                }
            }
        }
    }

    // ── onUpdate ─────────────────────────────────────────────────────────────

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        Log.d(TAG, "${this::class.simpleName} onUpdate ids=${appWidgetIds.toList()}")

        for (id in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, layoutResId)
                applyData(views, prefs)
                setLaunchIntent(context, views)
                setRefreshIntent(context, views, id)
                appWidgetManager.updateAppWidget(id, views)
            } catch (e: Exception) {
                Log.e(TAG, "onUpdate failed id=$id", e)
            }
        }
    }

    // ── onReceive: handles ACTION_REFRESH broadcast ───────────────────────────

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_REFRESH) return

        Log.d(TAG, "Refresh requested — scheduling expedited WorkManager task")

        val work = OneTimeWorkRequestBuilder<WeatherSyncWorker>()
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()

        WorkManager.getInstance(context)
            .enqueueUniqueWork("widget_refresh_now", ExistingWorkPolicy.REPLACE, work)

        // Immediately dim all refresh buttons to signal "loading"
        dimRefreshButtons(context)
    }

    /** Dims the refresh icon on every widget instance (visual "loading" hint). */
    private fun dimRefreshButtons(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val prefs   = HomeWidgetPlugin.getData(context)

        for (widgetClass in listOf(
            WeatherWidgetSmall::class.java,
            WeatherWidgetMedium::class.java,
            WeatherWidgetLarge::class.java
        )) {
            val ids = manager.getAppWidgetIds(ComponentName(context, widgetClass))
            // Instantiate without reflection via a factory method pattern
            val widget: BaseWeatherWidget? = when (widgetClass) {
                WeatherWidgetSmall::class.java  -> WeatherWidgetSmall()
                WeatherWidgetMedium::class.java -> WeatherWidgetMedium()
                WeatherWidgetLarge::class.java  -> WeatherWidgetLarge()
                else -> null
            } ?: continue

            for (id in ids) {
                try {
                    val views = RemoteViews(context.packageName, widget!!.layoutResId)
                    widget.applyData(views, prefs)
                    widget.setLaunchIntent(context, views)
                    widget.setRefreshIntent(context, views, id)
                    views.setFloat(widget.refreshViewId, "setAlpha", 0.25f)
                    manager.updateAppWidget(id, views)
                } catch (e: Exception) {
                    Log.e(TAG, "dimRefreshButtons failed", e)
                }
            }
        }
    }

    // ── PendingIntents ────────────────────────────────────────────────────────

    internal fun setLaunchIntent(context: Context, views: RemoteViews) {
        try {
            val intent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pi = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(rootViewId, pi)
        } catch (e: Exception) {
            Log.e(TAG, "setLaunchIntent failed", e)
        }
    }

    internal fun setRefreshIntent(context: Context, views: RemoteViews, widgetId: Int) {
        try {
            val intent = Intent(ACTION_REFRESH).apply {
                `package` = context.packageName
                // Уникальный requestCode per-widget гарантирует отдельный
                // PendingIntent для каждого экземпляра виджета.
            }
            // FLAG_CANCEL_CURRENT + FLAG_IMMUTABLE:
            // Удаляем старый интент и создаём новый — устраняет проблему
            // «мёртвых» интентов на Android 12+ (API 31+), где
            // FLAG_UPDATE_CURRENT|FLAG_IMMUTABLE конфликтуют.
            val pi = PendingIntent.getBroadcast(
                context, widgetId, intent,
                PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(refreshViewId, pi)
            views.setFloat(refreshViewId, "setAlpha", 0.55f)
        } catch (e: Exception) {
            Log.e(TAG, "setRefreshIntent failed", e)
        }
    }

    // ── Icon helpers ──────────────────────────────────────────────────────────

    protected fun str(prefs: SharedPreferences, key: String, fallback: String = ""): String =
        prefs.getString(key, fallback) ?: fallback

    protected fun iconResForCode(code: Int, isDay: Boolean): Int = when (code) {
        0, 1      -> if (isDay) R.drawable.ic_weather_sunny else R.drawable.ic_weather_night
        2         -> R.drawable.ic_weather_partly_cloudy
        3         -> R.drawable.ic_weather_cloudy
        45, 48    -> R.drawable.ic_weather_fog
        in 51..57 -> R.drawable.ic_weather_drizzle
        in 61..67 -> R.drawable.ic_weather_rain
        in 71..77 -> R.drawable.ic_weather_snow
        in 80..82 -> R.drawable.ic_weather_rain
        85, 86    -> R.drawable.ic_weather_snow
        in 95..99 -> R.drawable.ic_weather_thunderstorm
        else      -> R.drawable.ic_weather_cloudy
    }

    protected fun iconRes(
        prefs: SharedPreferences,
        codeKey: String = "wg_code",
        isDayKey: String = "wg_isday"
    ): Int {
        val code  = prefs.getString(codeKey, "0")?.toIntOrNull() ?: 0
        val isDay = prefs.getString(isDayKey, "1") == "1"
        return iconResForCode(code, isDay)
    }
}
