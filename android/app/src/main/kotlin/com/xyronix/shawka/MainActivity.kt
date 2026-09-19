package com.xyronix.shawka

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        ensureNotificationChannels()
    }

    private fun ensureNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return

        val channels = listOf(
            NotificationChannel(
                "matlobgo_general",
                "إشعارات عامة",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "عروض وتنبيهات شوكة و سكينة"
                enableVibration(true)
            },
            NotificationChannel(
                "matlobgo_orders",
                "تحديثات الطلبات",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "حالات الطلب والتوصيل"
                enableVibration(true)
            },
        )

        manager.createNotificationChannels(channels)
    }
}
