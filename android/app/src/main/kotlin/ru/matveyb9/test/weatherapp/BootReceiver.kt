package ru.matveyb9.test.weatherapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.*
import java.util.concurrent.TimeUnit

/**
 * Перерегистрирует периодическую задачу WorkManager после перезагрузки
 * устройства или обновления приложения.
 *
 * Без этого WorkManager-задача пропадает после reboot и виджет
 * перестаёт обновляться до следующего запуска приложения.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return

        Log.d(TAG, "Boot/update received — re-registering periodic sync")

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val request = PeriodicWorkRequestBuilder<WeatherSyncWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(BackoffPolicy.LINEAR, 5, TimeUnit.MINUTES)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            TASK_UNIQUE,
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )

        Log.d(TAG, "Periodic sync re-registered (15 min)")
    }

    companion object {
        private const val TAG = "BootReceiver"
        private const val TASK_UNIQUE = "ru.matveyb9.test.weatherapp.sync"
    }
}
